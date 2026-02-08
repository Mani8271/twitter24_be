class User < ApplicationRecord
  has_secure_password
  has_one_attached :profile_picture
  has_many :live_locations, dependent: :destroy
  validates :name, presence: true
  validates :phone_number, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :account_type, inclusion: { in: %w[user business] }

 
has_one :business, dependent: :destroy
has_one :onboarding_progress, dependent: :destroy
has_one :live_location, dependent: :destroy
 has_many :global_feeds

   validate :business_required_for_business_account

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
   def business_required_for_business_account
    if account_type == "business" && business.nil?
      errors.add(:business, "must exist for business accounts")
    end
  end
   def self.ransackable_attributes(auth_object = nil)
    ["blob_id", "created_at", "id", "id_value", "name", "record_id", "record_type"]
  end
    def self.ransackable_associations(auth_object = nil)
    ["business", "live_location", "live_locations", "onboarding_progress", "profile_picture_attachment", "profile_picture_blob"]
  end
    def self.ransackable_attributes(auth_object = nil)
    ["blob_id", "created_at", "id", "id_value", "name", "record_id", "record_type"]
  end
    def self.ransackable_attributes(auth_object = nil)
    ["blob_id", "created_at", "id", "id_value", "name", "record_id", "record_type"]
  end
end