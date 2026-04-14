module Api
  module V1
    class SubscriptionsController < ApplicationController
      # POST /api/v1/subscriptions/subscribe
      # Body: { plan_id: <integer> }
      def subscribe
        plan = SubscriptionPlan.active.find_by(id: params[:plan_id])

        unless plan
          return render json: { error: "Plan not found or inactive" }, status: :not_found
        end

        if current_user.update(
          subscription_plan_id:      plan.id,
          is_subscription_completed: true,
          # ── Snapshot the plan at this exact moment ───────────────────────
          # Future admin edits to the plan will NOT affect this subscriber.
          subscribed_features:       plan.features,
          subscribed_limits:         plan.limits,
          subscribed_ranges:         plan.ranges,
          subscribed_at:             Time.current
        )
          render json: current_user, serializer: UserSerializer, status: :ok
        else
          render json: { errors: current_user.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      # GET /api/v1/subscriptions/plans
      def plans
        subscription_plans = SubscriptionPlan.active

        render json: subscription_plans.map { |plan|
          enabled = plan.features

          # Only return limits/ranges for enabled features that actually have a value set
          limits = enabled.each_with_object({}) do |key, h|
            val = plan.limit_for(key)
            h[key] = val if val.present?
          end

          ranges = enabled.each_with_object({}) do |key, h|
            val = plan.range_for(key)
            h[key] = val if val.present?
          end

          {
            id:            plan.id,
            type:          plan.plan_type,
            features:      enabled,
            amounts:       plan.amounts,
            is_subscribed: current_user.subscription_plan_id == plan.id,
            limits:        limits,
            ranges:        ranges,
          }
        }
      end
    end
  end
end
