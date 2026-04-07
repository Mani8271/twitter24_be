module Api
  module V1
    class SubscriptionsController < ApplicationController
      # GET /api/v1/subscriptions/plans
      def plans
        subscription_plans = SubscriptionPlan.active

        render json: subscription_plans.map { |plan|
          {
            id:            plan.id,
            type:          plan.plan_type,
            features:      plan.features,
            amounts:       plan.amounts,
            is_subscribed: current_user.subscription_plan_id == plan.id
          }
        }
      end
    end
  end
end
