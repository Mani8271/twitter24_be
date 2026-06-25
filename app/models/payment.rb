class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :subscription_plan

  STATUSES = %w[pending success failed].freeze
  ACTIVATION_STATES = %w[pending activated failed].freeze

  validates :merchant_transaction_id, presence: true, uniqueness: true
  validates :amount_in_paise, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }

  scope :pending,    -> { where(status: "pending") }
  scope :successful, -> { where(status: "success") }
  scope :activated,  -> { where.not(subscription_activated_at: nil) }

  # Add webhook_audit_log if it doesn't exist (for legacy records)
  before_save :ensure_webhook_audit_log

  def amount_in_rupees
    amount_in_paise / 100.0
  end

  # Idempotency: Check if this payment has already activated a subscription
  def subscription_already_activated?
    subscription_activated_at.present?
  end

  # Idempotency: Safely mark subscription as activated
  # Returns true if activation succeeded, false if already activated
  def mark_subscription_activated!
    # Use database-level locking to prevent concurrent race conditions
    with_lock do
      # Check again inside lock (double-check pattern)
      return false if subscription_already_activated?

      self.subscription_activated_at = Time.current
      self.activation_locked_at = Time.current
      save!
      true
    end
  end

  # Webhook audit logging: record each webhook call
  def log_webhook_call(signature_hash:, verified:, response_code:, error_message: nil)
    self.webhook_audit_log ||= {}
    self.webhook_call_count = (webhook_call_count || 0) + 1

    entry = {
      call_number: webhook_call_count,
      timestamp: Time.current.iso8601,
      signature_hash: signature_hash,
      verified: verified,
      response_code: response_code,
      error: error_message
    }

    # Keep last 50 webhook calls
    log = (webhook_audit_log || {}).merge(
      "call_#{webhook_call_count}" => entry
    )

    if log.size > 50
      log = log.slice(*log.keys.last(50))
    end

    self.webhook_audit_log = log
    save!
  end

  # Webhook deduplication: check if this exact signature was already processed
  def webhook_signature_already_processed?(signature_hash)
    webhook_signature_hash == signature_hash
  end

  # Mark webhook as verified (first time only)
  def mark_webhook_verified!(signature_hash)
    return if webhook_verified_at.present? # Already verified

    self.webhook_verified_at = Time.current
    self.webhook_signature_hash = signature_hash
    self.webhook_last_signature = signature_hash
    save!
  end

  def self.ransackable_associations(auth_object = nil)
    ["subscription_plan", "user"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["amount_in_paise", "created_at", "gateway_response", "gst_in", "id", "id_value", "merchant_transaction_id", "paid_at", "phonepe_transaction_id", "status", "subscription_plan_id", "updated_at", "user_id"]
  end

  private

  def ensure_webhook_audit_log
    self.webhook_audit_log ||= {}
  end
end
