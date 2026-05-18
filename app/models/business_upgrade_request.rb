class BusinessUpgradeRequest < ApplicationRecord
  belongs_to :user

  STATUSES = %w[pending approved rejected].freeze

  validates :request_status, inclusion: { in: STATUSES }
  validates :requested_at,   presence: true
  validate  :no_active_request_exists,       on: :create
  validate  :rejection_reason_required,      on: :update
  validate  :status_transition_valid,        on: :update

  scope :pending,  -> { where(request_status: "pending")  }
  scope :approved, -> { where(request_status: "approved") }
  scope :rejected, -> { where(request_status: "rejected") }

  def self.ransackable_attributes(auth_object = nil)
    %w[id user_id request_status requested_at approved_by approved_at
       rejected_by rejected_at rejection_reason created_at]
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

  def rejection_reason_required
    return unless request_status == "rejected"
    return if rejection_reason.present?

    errors.add(:rejection_reason, "must be provided when rejecting a request")
  end

  # Only pending requests may be approved or rejected; terminal states are final.
  def status_transition_valid
    return unless request_status_changed?

    old_status = request_status_was
    new_status = request_status

    valid_transitions = {
      "pending"  => %w[approved rejected],
      "approved" => [],
      "rejected" => [],
    }

    return if (valid_transitions[old_status] || []).include?(new_status)

    errors.add(:request_status, "cannot transition from '#{old_status}' to '#{new_status}'")
  end
end
