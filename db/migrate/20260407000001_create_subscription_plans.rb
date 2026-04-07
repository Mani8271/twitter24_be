class CreateSubscriptionPlans < ActiveRecord::Migration[7.1]
  def change
    create_table :subscription_plans do |t|
      t.string  :plan_type, null: false
      t.jsonb   :features,  null: false, default: []
      t.string  :amounts,   null: false
      t.integer :position,  null: false, default: 0
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_index :subscription_plans, :plan_type, unique: true
    add_index :subscription_plans, :position
  end
end
