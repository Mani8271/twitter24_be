class OtpCode < ApplicationRecord
  belongs_to :user
  validates :user_id, :phone_number, :otp_number, :otp_expiry, presence: true
  validates :otp_number, uniqueness: true

  # Scopes for finding usable OTPs (unused AND not expired)
  scope :unused, -> { where(used_at: nil) }
  scope :valid, -> { where("otp_expiry > ?", Time.current) }
  scope :usable, -> { unused.valid }

  # Mark OTP as used to prevent reuse
  def mark_as_used!
    update!(used_at: Time.current)
  end

  def already_used?
    used_at.present?
  end

  def expired?
    otp_expiry < Time.current
  end

  def self.ransackable_associations(auth_object = nil)
    ["user"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "otp_expiry", "otp_number", "phone_number", "updated_at", "user_id", "used_at"]
  end
end
