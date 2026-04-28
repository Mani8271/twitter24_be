

class UserSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id,
             :name,
             :email,
             :phone_number,
             :profile_picture,
             :currency_pref,
             :is_online,
             :is_subscription_completed,
             :account_type,
             :email_verified,
             :phone_verified,
             :followed_businesses_count,
             :subscription_plan,
             :billing_address

  # ✅ Only for business accounts
  attribute :status, if: :business_account?
  attribute :onboarding_completed, if: :business_account?
  attribute :current_step, if: :business_account?
  attribute :steps_completed, if: :business_account?

  has_many :followed_businesses   

  # -------------------------------
  # Conditions
  # -------------------------------
  def business_account?
    object.account_type == "business"
  end

  # -------------------------------
  # Business Status
  # -------------------------------
  def status
    object.business&.status
  end

  # -------------------------------
  # Onboarding Info
  # -------------------------------
  def onboarding_completed
    object.onboarding_progress&.completed || false
  end

  def current_step
    object.onboarding_progress&.current_step
  end

  def steps_completed
    object.onboarding_progress&.steps_completed || []
  end

  # -------------------------------
  # Other Methods
  # -------------------------------
  def profile_picture
    return nil unless object.profile_picture.attached?

    object.profile_picture.blob.url
  end

  def is_online
    object.business&.is_online || false
  end

  def followed_businesses_count
    object.followed_businesses.count
  end

  # ─── Billing Address ───────────────────────────────────────────────────
  def billing_address
    loc = object.business&.business_location
    return nil unless loc
    [loc.address_line1, loc.address_line2, loc.city, loc.state].compact.reject(&:blank?).join(", ")
  end

  # ─── Subscription Plan ─────────────────────────────────────────────────
  # Returns the limits/ranges/features the user locked in at subscription
  # time — NOT the current live plan values.  Admin edits to the plan do not
  # change what existing subscribers see or are allowed to do.
  def subscription_plan
    plan = object.subscription_plan
    return nil unless plan

    # Use the snapshotted feature list (falls back to live plan for legacy rows)
    features = object.effective_features

    limits = features.each_with_object({}) do |key, h|
      val = object.effective_limit(key)
      h[key] = val if val.present?
    end

    ranges = features.each_with_object({}) do |key, h|
      val = object.effective_range(key)
      h[key] = val if val.present?
    end

    # Usage counts — active posts only (matches controller limit check)
    usage = {
      "offers"      => object.offers.active.count,
      "job_posts"   => object.jobs.count,
      "local_feed"  => object.global_feeds.where(feed_type: "local").count,
      "global_feed" => object.global_feeds.where(feed_type: "global").count,
    }

    {
      id:           plan.id,
      type:         plan.plan_type,
      features:     features,
      limits:       limits,
      ranges:       ranges,
      amounts:      plan.amounts,
      subscribed_at: object.subscribed_at,
      expires_at:   object.subscription_expires_at,
      is_expired:   object.subscription_expires_at.present? && object.subscription_expires_at < Time.current,
      usage:        usage
    }
  end
end

