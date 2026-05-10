

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
             :billing_address,
             :feature_blocks

  # ✅ Only for business accounts
  attribute :status, if: :business_account?
  attribute :rejection_reason, if: :business_account?
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

  def rejection_reason
    object.business&.rejection_reason
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

  # ─── Feature Blocks ────────────────────────────────────────────────────
  # Drives sidebar navigation and frontend feature-access checks.
  # The set of features is determined by account_type, not subscription plan —
  # all users can browse every section; posting rights are enforced separately.
  def feature_blocks
    base = [
      { feature: "local_feed",  url: "dashboard/local-feeds"  },
      { feature: "global_feed", url: "dashboard/global-feeds" },
      { feature: "radius",      url: "dashboard/radius"       },
      { feature: "vacancies",   url: "dashboard/vacancies"    },
      { feature: "offers",      url: "dashboard/offers"       },
    ]

    if business_account?
      base + [
        { feature: "my_domain",   url: "dashboard/my-domain"         },
        { feature: "subscription", url: "dashboard/subscription-plans" },
      ]
    else
      base
    end
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

    disappear_days = (features & SubscriptionPlan::DISAPPEARABLE_FEATURES).each_with_object({}) do |key, h|
      val = object.effective_disappear_days(key)
      h[key] = val if val.present?
    end

    # Usage counts — cumulative posts created this subscription cycle.
    # These counters increment on create and never decrement on delete/expire,
    # so deleting a post does not restore the quota. They reset when the user
    # starts a new subscription cycle (subscribe / cancel + re-subscribe).
    # domain_uploads is active count because it tracks gallery storage capacity.
    usage = {
      "offers"         => object.subscription_usage_count("offers"),
      "job_posts"      => object.subscription_usage_count("job_posts"),
      "local_feed"     => object.subscription_usage_count("local_feed"),
      "global_feed"    => object.subscription_usage_count("global_feed"),
      "domain_uploads" => object.business&.shop_images&.count || 0,
    }

    {
      id:             plan.id,
      type:           plan.plan_type,
      features:       features,
      limits:         limits,
      ranges:         ranges,
      disappear_days: disappear_days,
      amounts:        plan.amounts,
      subscribed_at:  object.subscribed_at,
      expires_at:     object.subscription_expires_at,
      is_expired:     object.subscription_expires_at.present? && object.subscription_expires_at < Time.current,
      usage:          usage
    }
  end
end

