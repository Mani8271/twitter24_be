class AddRangesToSubscriptionPlans < ActiveRecord::Migration[7.1]
  def change
    add_column :subscription_plans, :ranges, :jsonb, null: false, default: {}
  end
end
