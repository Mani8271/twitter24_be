module PlanAuthorized
  extend ActiveSupport::Concern

  # Halts with 403 if the current user's plan doesn't include the feature.
  # Returns true on success so you can chain: return unless require_feature!("offers")
  def require_feature!(feature_key)
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

  # Halts with 403 if the user has reached the per-plan limit for a feature.
  # Pass the current count of existing records for that feature.
  # Returns true when the user is within the limit (or the plan is unlimited).
  def check_limit!(feature_key, current_count)
    limit = current_user.feature_limit(feature_key)
    return true if limit.nil? # nil = unlimited on this plan

    if current_count >= limit
      render json: {
        error:         "You have reached the #{feature_key.to_s.humanize.downcase} " \
                       "limit (#{limit}) for your current plan.",
        feature_key:   feature_key,
        limit_reached: true,
        limit:         limit,
        current_count: current_count,
        upgrade_required: true
      }, status: :forbidden
      return false
    end
    true
  end
end
