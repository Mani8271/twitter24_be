# Service to safely activate subscriptions with idempotency protection.
#
# This service ensures:
# 1. Subscription is only activated ONCE per payment
# 2. Database-level locking prevents race conditions
# 3. Activation is atomic (all-or-nothing)
# 4. Audit trail is maintained
#
# CRITICAL: This should be called ONLY from the webhook handler, never from
# user-facing endpoints (like the status polling API).
class SubscriptionActivationService
  def initialize(payment:)
    @payment = payment
    @user = payment.user
    @plan = payment.subscription_plan
  end

  # Atomically activate subscription, or return early if already activated
  #
  # @return [Result] { success: true/false, reason: nil/message, user_updated: true/false }
  def activate
    # Check if already activated (quick check before lock)
    if @payment.subscription_already_activated?
      Rails.logger.info "[SubscriptionActivation] Payment #{@payment.id} already activated, skipping"
      return Result.new(success: false, reason: "already_activated", user_updated: false)
    end

    # Idempotency: Use database lock to prevent concurrent race conditions
    success = @payment.mark_subscription_activated!
    unless success
      Rails.logger.info "[SubscriptionActivation] Failed to acquire lock for payment #{@payment.id}"
      return Result.new(success: false, reason: "lock_failed", user_updated: false)
    end

    # Now actually update the subscription
    result = update_user_subscription
    unless result
      Rails.logger.error "[SubscriptionActivation] Failed to update user subscription for payment #{@payment.id}"
      return Result.new(success: false, reason: "update_failed", user_updated: false)
    end

    Rails.logger.info "[SubscriptionActivation] ✓ Successfully activated subscription for user #{@user.id} via payment #{@payment.id}"
    Result.new(success: true, reason: nil, user_updated: true)
  end

  private

  def update_user_subscription
    switching_plan = @user.subscription_plan_id != @plan.id
    new_usage = switching_plan ? {} : (@user.subscription_usage || {})

    @user.update!(
      subscription_plan_id:      @plan.id,
      is_subscription_completed: true,
      subscribed_features:       @plan.features,
      subscribed_limits:         @plan.limits,
      subscribed_ranges:         @plan.ranges,
      subscribed_disappear_days: @plan.disappear_days,
      subscribed_at:             Time.current,
      subscription_expires_at:   Time.current + 30.days,
      subscription_usage:        new_usage
    )

    # Also update payment metadata
    @payment.update!(
      paid_at: Time.current,
      phonepe_transaction_id: extract_phonepe_transaction_id
    )

    true
  rescue StandardError => e
    Rails.logger.error "[SubscriptionActivation] Update failed: #{e.class} #{e.message}"
    false
  end

  def extract_phonepe_transaction_id
    # Extract PhonePe transaction ID from gateway response if available
    return nil unless @payment.gateway_response.is_a?(Hash)
    @payment.gateway_response.dig("data", "transactionId") ||
      @payment.gateway_response.dig("transactionId")
  end

  # Simple result object
  class Result
    attr_reader :success, :reason, :user_updated

    def initialize(success:, reason:, user_updated:)
      @success = success
      @reason = reason
      @user_updated = user_updated
    end

    def to_h
      { success: success, reason: reason, user_updated: user_updated }
    end
  end
end
