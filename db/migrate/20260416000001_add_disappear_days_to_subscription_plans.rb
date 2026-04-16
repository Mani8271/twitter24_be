class AddDisappearDaysToSubscriptionPlans < ActiveRecord::Migration[7.1]
  def change
    add_column :subscription_plans, :disappear_days, :jsonb, default: {}, null: false
    add_column :users, :subscribed_disappear_days, :jsonb, default: {}
  end
end
