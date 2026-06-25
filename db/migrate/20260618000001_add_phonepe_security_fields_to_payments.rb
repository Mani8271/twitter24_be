class AddPhonepeSecurityFieldsToPayments < ActiveRecord::Migration[7.1]
  def change
    # Track webhook calls and verification
    add_column :payments, :webhook_call_count,      :integer,  default: 0
    add_column :payments, :webhook_verified_at,     :datetime
    add_column :payments, :webhook_signature_hash,  :string
    add_column :payments, :webhook_last_signature,  :string

    # Audit trail: all webhook calls with timestamps and responses
    add_column :payments, :webhook_audit_log,       :jsonb,    default: {}

    # Activation tracking for idempotency
    add_column :payments, :subscription_activated_at, :datetime
    add_column :payments, :activation_locked_at,    :datetime  # Lock for concurrent requests

    # Add indexes for webhook lookups and duplicate detection
    add_index :payments, :webhook_signature_hash, unique: true, name: "idx_payments_webhook_signature"
    add_index :payments, [:user_id, :merchant_transaction_id], unique: true, name: "idx_payments_user_txn_id"
    add_index :payments, :webhook_verified_at,  name: "idx_payments_webhook_verified"
    add_index :payments, :subscription_activated_at, name: "idx_payments_subscription_activated"
  end
end
