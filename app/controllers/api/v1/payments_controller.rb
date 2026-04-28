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

        activate_subscription(payment) if new_status == "success"

        render json: payment_status_response(payment)

      rescue KeyError => e
        render json: { error: "Payment gateway not configured: #{e.message}" }, status: :service_unavailable
      end

      # POST /api/v1/payments/webhook  (PhonePe server-to-server callback, no JWT)
      def webhook
        unless valid_webhook_credentials?
          Rails.logger.warn "[PaymentWebhook] Invalid credentials"
          return head :unauthorized
        end

        body    = parse_json(request.raw_post)
        state   = body.dig("payload", "state") || body["state"]
        txn_id  = body.dig("payload", "merchantOrderId") || body["merchantOrderId"]

        payment = Payment.find_by(merchant_transaction_id: txn_id)
        return head :ok unless payment && payment.status == "pending"

        new_status = map_phonepe_state(state)

        payment.update!(
          status:           new_status,
          gateway_response: body,
          paid_at:          new_status == "success" ? Time.current : nil
        )

        activate_subscription(payment) if new_status == "success"
        head :ok

      rescue StandardError => e
        Rails.logger.error "[PaymentWebhook] #{e.class}: #{e.message}"
        head :ok
      end

      private

      def valid_webhook_credentials?
        expected_user = ENV.fetch("PHONEPE_WEBHOOK_USERNAME", "")
        expected_pass = ENV.fetch("PHONEPE_WEBHOOK_PASSWORD", "")
        return true if expected_user.blank?

        credentials = ActionController::HttpAuthentication::Basic.user_name_and_password(request) rescue [nil, nil]
        # Accept if no credentials sent (PhonePe validation ping) OR credentials match
        return true if credentials[0].blank?

        ActiveSupport::SecurityUtils.secure_compare(credentials[0].to_s, expected_user) &&
          ActiveSupport::SecurityUtils.secure_compare(credentials[1].to_s, expected_pass)
      end

      def phonepe_service
        @phonepe_service ||= PhonePeService.new
      end

      def activate_subscription(payment)
        plan = payment.subscription_plan
        payment.user.update!(
          subscription_plan_id:      plan.id,
          is_subscription_completed: true,
          subscribed_features:       plan.features,
          subscribed_limits:         plan.limits,
          subscribed_ranges:         plan.ranges,
          subscribed_disappear_days: plan.disappear_days,
          subscribed_at:             Time.current,
          subscription_expires_at:   Time.current + 30.days
        )
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
