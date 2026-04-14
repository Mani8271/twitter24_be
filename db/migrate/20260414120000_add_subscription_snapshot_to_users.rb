class AddSubscriptionSnapshotToUsers < ActiveRecord::Migration[7.1]
  def change
    # Snapshot of plan data locked in at subscription time.
    # These never change even if the admin later edits the plan.
    add_column :users, :subscribed_features, :jsonb, default: []
    add_column :users, :subscribed_limits,   :jsonb, default: {}
    add_column :users, :subscribed_ranges,   :jsonb, default: {}
    add_column :users, :subscribed_at,       :datetime
  end
end
