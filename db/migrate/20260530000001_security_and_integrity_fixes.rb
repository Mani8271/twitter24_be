class SecurityAndIntegrityFixes < ActiveRecord::Migration[7.1]
  def up
    # ── C12: Unique composite index on follows ────────────────────────────────
    # Prevents a user from following the same business/entity more than once.
    # Remove any existing duplicates before adding the constraint.
    execute <<~SQL
      DELETE FROM follows
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM follows
        GROUP BY user_id, followable_type, followable_id
      )
    SQL
    add_index :follows, [:user_id, :followable_type, :followable_id],
              unique: true,
              name: "index_follows_on_user_followable_unique"

    # ── H10: Foreign key for global_feeds.user_id ─────────────────────────────
    # Prevents orphaned feed records when users are removed.
    # First clean up any orphans that exist from soft-deleted users.
    execute <<~SQL
      DELETE FROM global_feeds
      WHERE user_id NOT IN (SELECT id FROM users)
    SQL
    add_foreign_key :global_feeds, :users, on_delete: :cascade

    # ── M3: Index on comments.parent_id (reply thread loading) ───────────────
    add_index :comments, :parent_id, name: "index_comments_on_parent_id"

    # ── M4: NOT NULL constraints on critical columns ──────────────────────────
    # businesses.status — backfill NULL rows to 'draft' first
    execute "UPDATE businesses SET status = 'draft' WHERE status IS NULL"
    change_column_null :businesses, :status, false

    # users.status — backfill NULL rows to '' (empty means no special state)
    execute "UPDATE users SET status = '' WHERE status IS NULL"
    change_column_null :users, :status, false, ""

    # ── L2: Check constraint on businesses.status ─────────────────────────────
    execute <<~SQL
      ALTER TABLE businesses
      ADD CONSTRAINT businesses_status_check
      CHECK (status IN ('draft', 'submitted', 'approved', 'rejected'))
    SQL
  end

  def down
    execute "ALTER TABLE businesses DROP CONSTRAINT IF EXISTS businesses_status_check"
    change_column_null :businesses, :status, true
    change_column_null :users, :status, true
    remove_index :comments, name: "index_comments_on_parent_id"
    remove_foreign_key :global_feeds, :users
    remove_index :follows, name: "index_follows_on_user_followable_unique"
  end
end
