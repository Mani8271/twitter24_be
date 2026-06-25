module Api
  module V1
    class PaymentsController < ApplicationController
      wrap_parameters false

      skip_before_action :verify_authenticity_token, only: [:webhook]
      skip_before_action :authorize_request,         only: [:webhook]

      # GET /api/v1/payments/history
      def history
        payments = current_user.payments
                               .includes(:subscription_plan)
                               .order(created_at: :desc)
                               .limit(50)

        render json: payments.map { |p|
          {
            id:                      p.id,
            date:                    p.paid_at || p.created_at,
            merchant_transaction_id: p.merchant_transaction_id,
            plan:                    p.subscription_plan.plan_type,
            amount:                  p.amount_in_rupees,
            gst_in:                  p.gst_in,
            status:                  p.status,
          }
        }
      end

      # POST /api/v1/payments/initiate
      # Body: { plan_id, merchant_transaction_id, redirect_url, gst_in? }
      def initiate
        plan = SubscriptionPlan.active.find_by(id: params[:plan_id])
        return render json: { error: "Plan not found or inactive" }, status: :not_found unless plan

        merchant_transaction_id = params[:merchant_transaction_id].to_s.strip
        if merchant_transaction_id.blank?
          return render json: { error: "merchant_transaction_id is required" }, status: :unprocessable_entity
        end

        amount_in_paise = plan.amounts.to_i * 100

        payment = Payment.create!(
          user:                    current_user,
          subscription_plan:       plan,
          merchant_transaction_id: merchant_transaction_id,
          amount_in_paise:         amount_in_paise,
          gst_in:                  params[:gst_in].presence,
          status:                  "pending"
        )

        result = phonepe_service.initiate_payment(
          merchant_order_id: merchant_transaction_id,
          amount_in_paise:   amount_in_paise,
          redirect_url:      params[:redirect_url]
        )

        unless result[:success]
          payment.update!(status: "failed", gateway_response: { message: result[:message] })
          return render json: { error: result[:message] || "Payment initiation failed" },
                        status: :unprocessable_entity
        end

        payment.update!(gateway_response: { order_id: result[:order_id] })

        render json: {
          redirect_url:            result[:redirect_url],
          merchant_transaction_id: merchant_transaction_id
        }, status: :ok

      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue KeyError => e
        render json: { error: "Payment gateway not configured: #{e.message}" }, status: :service_unavailable
      end

      # GET /api/v1/payments/status/:merchant_transaction_id
      # IMPORTANT: This endpoint is for POLLING ONLY — it does NOT activate subscriptions.
      # Subscriptions are activated ONLY via verified PhonePe webhook callbacks.
      def status
        payment = Payment.find_by(merchant_transaction_id: params[:merchant_transaction_id])
        return render json: { error: "Payment not found" }, status: :not_found unless payment
        return render json: { error: "Unauthorized" }, status: :forbidden unless payment.user_id == current_user.id

        if payment.status.in?(%w[success failed])
          return render json: payment_status_response(payment)
        end

        result     = phonepe_service.check_status(payment.merchant_transaction_id)
        new_status = map_phonepe_state(result[:state])

        payment.update!(
          status:           new_status,
          gateway_response: result[:data] || {},
          paid_at:          new_status == "success" ? Time.current : nil
        )

        # ⚠️  DO NOT activate subscription here!
        # Subscriptions are activated ONLY by verified webhook from PhonePe.
        # Frontend polling is not a trusted source.

        render json: payment_status_response(payment)

      rescue KeyError => e
        render json: { error: "Payment gateway not configured: #{e.message}" }, status: :service_unavailable
      end

      # POST /api/v1/payments/webhook  (PhonePe server-to-server callback, no JWT)
      # CRITICAL: This is the ONLY place where subscriptions are activated.
      # Security: Verifies PhonePe signature + deduplicates webhook calls.
      def webhook
        webhook_result = handle_phonepe_webhook

        # Always return 200 OK to PhonePe (even on errors) to prevent retries.
        # Errors are logged for investigation.
        render json: { success: webhook_result[:success], message: webhook_result[:message] }, status: :ok

      rescue StandardError => e
        Rails.logger.error "[PaymentWebhook] Unhandled exception: #{e.class} #{e.message}\n#{e.backtrace.join("\n")}"
        render json: { success: false, message: "Internal error" }, status: :ok
      end

      private

      # Complete webhook handler with signature verification and idempotency
      def handle_phonepe_webhook
        raw_body = request.raw_post
        x_verify_header = request.headers["X-Verify"]

        Rails.logger.info "[PaymentWebhook] Received webhook"

        # Step 1: Verify PhonePe signature
        verifier = PhonePeWebhookVerifier.new
        verification_result = verifier.verify(x_verify_header: x_verify_header, raw_body: raw_body)

        unless verification_result[:valid]
          Rails.logger.warn "[PaymentWebhook] ✗ Signature verification failed: #{verification_result[:error]}"
          return { success: false, message: verification_result[:error] }
        end

        # Step 2: Parse webhook payload
        body = parse_json(raw_body)
        unless body.is_a?(Hash)
          Rails.logger.warn "[PaymentWebhook] Invalid JSON payload"
          return { success: false, message: "Invalid payload" }
        end

        # Step 3: Extract payment details
        state = body.dig("payload", "state") || body["state"]
        txn_id = body.dig("payload", "merchantOrderId") || body["merchantOrderId"]

        unless txn_id.present? && state.present?
          Rails.logger.warn "[PaymentWebhook] Missing merchantOrderId or state in payload"
          return { success: false, message: "Missing fields" }
        end

        # Step 4: Find payment record
        payment = Payment.find_by(merchant_transaction_id: txn_id)
        unless payment
          Rails.logger.warn "[PaymentWebhook] Payment not found for txn_id=#{txn_id}"
          return { success: false, message: "Payment not found" }
        end

        # Step 5: Check for webhook signature deduplication (replay attack protection)
        signature_hash = verification_result[:signature_hash]
        if payment.webhook_signature_already_processed?(signature_hash)
          Rails.logger.info "[PaymentWebhook] ✓ Webhook already processed (dedup), ignoring: #{txn_id}"
          payment.log_webhook_call(
            signature_hash: signature_hash,
            verified: true,
            response_code: 200,
            error_message: "Duplicate (already processed)"
          )
          return { success: true, message: "Webhook already processed" }
        end

        # Step 6: Update payment status
        new_status = map_phonepe_state(state)
        payment.update!(
          status: new_status,
          gateway_response: body
        )

        # Log this webhook call
        payment.mark_webhook_verified!(signature_hash)

        # Step 7: Activate subscription ONLY if payment succeeded
        activation_result = nil
        if new_status == "success"
          activation_service = SubscriptionActivationService.new(payment: payment)
          activation_result = activation_service.activate
          Rails.logger.info "[PaymentWebhook] Activation result: #{activation_result.to_h}"
        else
          Rails.logger.info "[PaymentWebhook] Payment status is #{new_status}, not activating subscription"
        end

        # Step 8: Log webhook completion
        payment.log_webhook_call(
          signature_hash: signature_hash,
          verified: true,
          response_code: 200,
          error_message: nil
        )

        { success: true, message: "Webhook processed" }
      end

      def valid_webhook_credentials?
        expected_user = ENV.fetch("PHONEPE_WEBHOOK_USERNAME", "")
        expected_pass = ENV.fetch("PHONEPE_WEBHOOK_PASSWORD", "")

        if expected_user.blank?
          Rails.logger.warn "[PaymentWebhook] PHONEPE_WEBHOOK_USERNAME not configured — rejecting request"
          return false
        end

        credentials = ActionController::HttpAuthentication::Basic.user_name_and_password(request) rescue [nil, nil]

        return false if credentials[0].blank?

        ActiveSupport::SecurityUtils.secure_compare(credentials[0].to_s, expected_user) &&
          ActiveSupport::SecurityUtils.secure_compare(credentials[1].to_s, expected_pass)
      end

      def phonepe_service
        @phonepe_service ||= PhonePeService.new
      end

      # Maps PhonePe v2 order state to internal status
      def map_phonepe_state(state)
        case state.to_s.upcase
        when "COMPLETED" then "success"
        when "FAILED", "CANCELLED" then "failed"
        else "pending"
        end
      end

      def payment_status_response(payment)
        {
          status:                  payment.status,
          merchant_transaction_id: payment.merchant_transaction_id,
          amount:                  payment.amount_in_rupees,
          plan_type:               payment.subscription_plan.plan_type
        }
      end

      def parse_json(raw)
        JSON.parse(raw)
      rescue JSON::ParserError
        {}
      end
    end
  end
end
