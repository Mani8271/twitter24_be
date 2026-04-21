class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :subscription_plan

  STATUSES = %w[pending success failed].freeze

  validates :merchant_transaction_id, presence: true, uniqueness: true
  validates :amount_in_paise, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }

  scope :pending,    -> { where(status: "pending") }
  scope :successful, -> { where(status: "success") }

  def amount_in_rupees
    amount_in_paise / 100.0
  end

    def self.ransackable_associations(auth_object = nil)
    ["subscription_plan", "user"]
  end

    def self.ransackable_attributes(auth_object = nil)
    ["amount_in_paise", "created_at", "gateway_response", "gst_in", "id", "id_value", "merchant_transaction_id", "paid_at", "phonepe_transaction_id", "status", "subscription_plan_id", "updated_at", "user_id"]
  end
end
