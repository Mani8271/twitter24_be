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
 belongs_to :subscription_plan, optional: true
 has_many :payments, dependent: :nullify

 # ── Subscription usage tracking ───────────────────────────────────────────
 # Tracks cumulative posts created per feature key within the current
 # subscription cycle. Counts never decrease on delete/expire — they reset
 # only when the user subscribes to a (new) plan via reset_subscription_usage!
 USAGE_FEATURE_KEYS = %w[offers job_posts local_feed global_feed].freeze

 # Returns how many posts this user has created for a feature in this cycle.
 def subscription_usage_count(feature_key)
   (subscription_usage || {})[feature_key.to_s].to_i
 end

 # Atomically increments the cumulative counter for a feature.
 # Uses a raw SQL JSONB update so concurrent requests don't clobber each other.
 def increment_subscription_usage!(feature_key)
   key = feature_key.to_s
   raise ArgumentError, "Invalid usage key: #{key}" unless key.in?(USAGE_FEATURE_KEYS)

   User.where(id: id).update_all(
     "subscription_usage = jsonb_set(" \
     "  COALESCE(subscription_usage, '{}')," \
     "  '{#{key}}'," \
     "  to_jsonb(COALESCE((subscription_usage->>'#{key}')::int, 0) + 1)" \
     ")"
   )
   reload
 end

 # Resets all usage counters to zero.
 # Call this when a user subscribes to a new plan (fresh cycle).
 def reset_subscription_usage!
   update_column(:subscription_usage, {})
 end

 # ── Subscription snapshot helpers ─────────────────────────────────────────
 # Limits, ranges, and features are snapshotted at subscription time so that
 # admin edits to the plan never retroactively affect existing subscribers.
 # Each method falls back to the live plan value for legacy users who have no
 # snapshot yet (subscribed_at.nil?).

 def has_feature?(feature_key)
   effective_features.include?(feature_key.to_s)
 end

 def feature_limit(feature_key)
   effective_limit(feature_key)
 end

 def effective_features
   if subscribed_at.present? && subscribed_features.present?
     subscribed_features
   else
     subscription_plan&.features || []
   end
 end

 def effective_limit(feature_key)
   key = feature_key.to_s
   if subscribed_at.present? && subscribed_limits.key?(key)
     val = subscribed_limits[key]
     val.present? ? val.to_i : nil   # nil = unlimited
   else
     subscription_plan&.limit_for(key)
   end
 end

 def effective_range(feature_key)
   key = feature_key.to_s
   if subscribed_at.present? && subscribed_ranges.key?(key)
     val = subscribed_ranges[key]
     val.present? ? val.to_i : nil
   else
     subscription_plan&.range_for(key)
   end
 end

 def effective_disappear_days(feature_key)
   key = feature_key.to_s
   if subscribed_at.present? && subscribed_disappear_days&.key?(key)
     val = subscribed_disappear_days[key]
     val.present? ? val.to_i : nil   # nil = no limit
   else
     subscription_plan&.disappear_days_for(key)
   end
 end

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
      otp_expiry: 5.minutes.from_now
    )
    otp
  end
   def business_required_for_business_account
    if account_type == "business" && business.nil?
      errors.add(:business, "must exist for business accounts")
    end
  end
  def self.ransackable_attributes(auth_object = nil)
    %w[id name email phone_number account_type status is_active deleted_at created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[business live_location live_locations onboarding_progress profile_picture_attachment profile_picture_blob]
  end
end