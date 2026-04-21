class CreatePayments < ActiveRecord::Migration[7.1]
  def change
    create_table :payments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :subscription_plan, null: false, foreign_key: true
      t.string  :merchant_transaction_id, null: false
      t.string  :phonepe_transaction_id
      t.integer :amount_in_paise, null: false
      t.string  :gst_in
      t.string  :status, null: false, default: "pending"
      t.jsonb   :gateway_response, default: {}
      t.datetime :paid_at

      t.timestamps
    end

    add_index :payments, :merchant_transaction_id, unique: true
    add_index :payments, :status
  end
end
