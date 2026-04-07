class AddSubscriptionPlanIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :subscription_plan_id, :bigint
    add_index  :users, :subscription_plan_id
    add_foreign_key :users, :subscription_plans
  end
end
