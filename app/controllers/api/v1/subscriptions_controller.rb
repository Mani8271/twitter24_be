module Api
  module V1
    class SubscriptionsController < ApplicationController
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
