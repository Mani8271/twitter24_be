class AddSubscriptionUsageToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :subscription_usage, :jsonb, default: {}, null: false
    add_index  :users, :subscription_usage, using: :gin
  end
end
