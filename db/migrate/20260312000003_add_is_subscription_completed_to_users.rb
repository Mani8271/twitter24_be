class AddIsSubscriptionCompletedToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :is_subscription_completed, :boolean, default: false, null: false
  end
end
