class OtpCode < ApplicationRecord
  belongs_to :user
    validates :user_id, :phone_number, :otp_number, :otp_expiry, presence: true
  validates :otp_number, uniqueness: true
    def self.ransackable_associations(auth_object = nil)
    ["user"]
  end
   def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "otp_expiry", "otp_number", "phone_number", "updated_at", "user_id"]
  end
end
