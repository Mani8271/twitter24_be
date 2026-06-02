module Api
  module V1
    class SubscriptionsController < ApplicationController
      # POST /api/v1/subscriptions/subscribe
      # Body: { plan_id: <integer> }
      # NOTE: Paid plans require a successful payment first. Activation for paid
      # plans happens automatically via the webhook or status-check flow. This
      # endpoint only handles zero-cost (free/trial) plans directly.
      def subscribe
        plan = SubscriptionPlan.active.find_by(id: params[:plan_id])

        unless plan
          return render json: { error: "Plan not found or inactive" }, status: :not_found
        end

        # Block direct activation of paid plans — must go through payment flow.
        if plan.amounts.to_i > 0
          return render json: {
            error:            "Payment is required to subscribe to this plan. Please use the payment flow.",
            payment_required: true,
            plan_id:          plan.id
          }, status: :payment_required
        end

        # Only wipe usage counters when the user is switching to a different plan.
        # Renewing the same plan (re-subscribe after expiry) preserves the cumulative
        # usage so that expired posts don't silently restore posting quota.
        switching_plan = current_user.subscription_plan_id != plan.id
        new_usage      = switching_plan ? {} : (current_user.subscription_usage || {})

        if current_user.update(
          subscription_plan_id:         plan.id,
          is_subscription_completed:    true,
          # ── Snapshot the plan at this exact moment ───────────────────────
          # Future admin edits to the plan will NOT affect this subscriber.
          subscribed_features:          plan.features,
          subscribed_limits:            plan.limits,
          subscribed_ranges:            plan.ranges,
          subscribed_disappear_days:    plan.disappear_days,
          subscribed_at:                Time.current,
          subscription_expires_at:      Time.current + 30.days,
          subscription_usage:           new_usage
        )
          render json: current_user, serializer: UserSerializer, status: :ok
        else
          render json: { errors: current_user.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/subscriptions/cancel
      def cancel
        unless current_user.subscription_plan_id.present? && current_user.is_subscription_completed
          return render json: { error: "No active subscription to cancel." }, status: :unprocessable_entity
        end

        if current_user.update(
          subscription_plan_id:      nil,
          is_subscription_completed: false,
          subscribed_features:       nil,
          subscribed_limits:         nil,
          subscribed_ranges:         nil,
          subscribed_disappear_days: nil,
          subscribed_at:             nil,
          subscription_expires_at:   nil,
          subscription_usage:        {}
        )
          render json: current_user, serializer: UserSerializer, status: :ok
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/subscriptions/plans
      def plans
        subscription_plans = SubscriptionPlan.active

        render json: subscription_plans.map { |plan|
          enabled = plan.features

          # Only return limits/ranges/disappear_days for enabled features that actually have a value set
          limits = enabled.each_with_object({}) do |key, h|
            val = plan.limit_for(key)
            h[key] = val if val.present?
          end

          ranges = enabled.each_with_object({}) do |key, h|
            val = plan.range_for(key)
            h[key] = val if val.present?
          end

          disappear_days = (enabled & SubscriptionPlan::DISAPPEARABLE_FEATURES).each_with_object({}) do |key, h|
            val = plan.disappear_days_for(key)
            h[key] = val if val.present?
          end

          {
            id:             plan.id,
            type:           plan.plan_type,
            features:       enabled,
            amounts:        plan.amounts,
            is_subscribed:  current_user.subscription_plan_id == plan.id,
            limits:         limits,
            ranges:         ranges,
            disappear_days: disappear_days,
          }
        }
      end
    end
  end
end
