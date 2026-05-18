module PlanAuthorized
  extend ActiveSupport::Concern

  # Halts with 403 if the user's subscription has expired.
  # A nil expires_at means the user is on a free plan or has no subscription — in
  # that case require_feature! will gate them correctly via has_feature?. We only
  # block when there IS a recorded expiry and it has already passed.
  # Returns true when active; false (already rendered) when expired.
  def require_active_subscription!
    expires_at = current_user.subscription_expires_at
    return true if expires_at.nil? || expires_at >= Time.current

    render json: {
      error:                "Your subscription has expired. Please renew to continue using this feature.",
      subscription_expired: true,
      expired_at:           expires_at.iso8601
    }, status: :forbidden
    false
  end

  # Halts with 403 if the current user's plan doesn't include the feature.
  # Also blocks expired subscriptions before the feature check (checked first).
  # Returns true on success so you can chain: return unless require_feature!("offers")
  def require_feature!(feature_key)
    return false unless require_active_subscription!
    return true if current_user.has_feature?(feature_key)

    plan = current_user.subscription_plan
    render json: {
      error:            "Your current plan does not include this feature.",
      feature_required: feature_key,
      upgrade_required: true,
      current_plan:     plan&.plan_type || "none"
    }, status: :forbidden
    false
  end

  # Halts with 422 if the requested disappear_after exceeds the plan's allowed
  # maximum for the given feature. Pass nil/blank to skip the check (no timer set).
  # Returns true when the value is within the plan's limit (or the plan is unlimited).
  def check_disappear_days!(feature_key, requested_days)
    return true if requested_days.blank?

    max = current_user.effective_disappear_days(feature_key)
    return true if max.nil?   # nil = unlimited on this plan

    days = requested_days.to_i
    if days > max
      render json: {
        error:                   "Your plan allows a maximum disappearing timer of #{max} day(s) " \
                                 "for #{feature_key.to_s.humanize.downcase} posts.",
        feature_key:             feature_key,
        disappear_days_exceeded: true,
        max_days:                max,
        requested_days:          days
      }, status: :unprocessable_entity
      return false
    end
    true
  end

  # Halts with 403 if the user has reached the per-plan limit for a feature.
  # Uses the persistent subscription_usage counter (not active post count) so
  # that deleted or auto-expired posts do NOT restore consumed quota.
  # Returns true when the user is within the limit (or the plan is unlimited).
  def check_limit!(feature_key)
    limit = current_user.feature_limit(feature_key)
    return true if limit.nil? # nil = unlimited on this plan

    usage = current_user.subscription_usage_count(feature_key)
    if usage >= limit
      render json: {
        error:            "You have reached the #{feature_key.to_s.humanize.downcase} " \
                          "limit (#{limit}) for your current plan.",
        feature_key:      feature_key,
        limit_reached:    true,
        limit:            limit,
        current_count:    usage,
        upgrade_required: true
      }, status: :forbidden
      return false
    end
    true
  end
end
