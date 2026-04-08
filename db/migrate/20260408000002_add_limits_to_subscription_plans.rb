class AddLimitsToSubscriptionPlans < ActiveRecord::Migration[7.1]
  def change
    add_column :subscription_plans, :limits, :jsonb, null: false, default: {}
  end
end
