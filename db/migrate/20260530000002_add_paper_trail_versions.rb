class AddPaperTrailVersions < ActiveRecord::Migration[7.1]
  def change
    create_table :versions do |t|
      t.string   :item_type, null: false
      t.bigint   :item_id,   null: false
      t.string   :event,     null: false
      t.string   :whodunnit
      t.text     :object
      t.text     :object_changes
      t.jsonb    :meta,      default: {}
      t.datetime :created_at
    end

    add_index :versions, [:item_type, :item_id]
    add_index :versions, :whodunnit
    add_index :versions, :created_at
  end
end
