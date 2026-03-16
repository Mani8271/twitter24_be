class User < ApplicationRecord
  has_secure_password
  has_one_attached :profile_picture

  default_scope { where(deleted_at: nil) }

  def soft_delete!
    update_column(:deleted_at, Time.current)
  end

  def deleted?
    deleted_at.present?
  end
  has_many :live_locations, dependent: :destroy
  validates :name, presence: true
  validates :phone_number, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :account_type, inclusion: { in: %w[user business] }

 
has_one :business, dependent: :destroy
has_one :onboarding_progress, dependent: :destroy
has_one :live_location, dependent: :destroy
 has_many :global_feeds

 validate :business_required_for_business_account, on: :update

 has_many :follows, dependent: :destroy

 has_many :offers, dependent: :destroy
 has_many :jobs, dependent: :destroy

 has_many :followed_businesses,
          -> { where(follows: { followable_type: "Business" }) },
          through: :follows,
          source: :followable,
          source_type: "Business"


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
    %w[id name email phone_number account_type status created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[business live_location live_locations onboarding_progress profile_picture_attachment profile_picture_blob]
  end
end