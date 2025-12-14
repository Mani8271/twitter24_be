class User < ApplicationRecord
  has_secure_password

  validates :name, presence: true
  validates :phone_number, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
 

 

  def generate_otp
    
    otp = rand(100000..999999).to_s

    OtpCode.create!(
      user_id: id,
      phone_number: phone_number,
      otp_number: otp,
      otp_expiry: 10.minutes.from_now
    )
    otp
  end
   def self.ransackable_attributes(auth_object = nil)
    ["account_type", "country_id", "created_at", "currency_pref", "current_location_size_id", "email", "email_verified", "followin_business", "id", "id_value", "is_online", "name", "password_digest", "phone_number", "phone_verified", "profile_picture", "region_id", "status", "updated_at", "zone_location_id"]
  end
end