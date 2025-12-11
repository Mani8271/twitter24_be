class OtpCode < ApplicationRecord
  belongs_to :user
    validates :user_id, :phone_number, :otp_number, :otp_expiry, presence: true
  validates :otp_number, uniqueness: true
end
