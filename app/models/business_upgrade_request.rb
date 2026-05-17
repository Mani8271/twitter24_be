class BusinessUpgradeRequest < ApplicationRecord
  belongs_to :user

  STATUSES = %w[pending approved rejected].freeze

  validates :request_status, inclusion: { in: STATUSES }
  validates :requested_at,   presence: true
  validate  :no_active_request_exists, on: :create

  scope :pending,  -> { where(request_status: "pending")  }
  scope :approved, -> { where(request_status: "approved") }
  scope :rejected, -> { where(request_status: "rejected") }

  def self.ransackable_attributes(auth_object = nil)
    %w[id user_id request_status requested_at approved_by approved_at rejection_reason created_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[user]
  end

  private

  # Each user may have at most one pending or approved request at a time.
  def no_active_request_exists
    return unless user_id.present?

    if BusinessUpgradeRequest.where(user_id: user_id, request_status: %w[pending approved]).exists?
      errors.add(:base, "You already have an active upgrade request.")
    end
  end
end
