class BusinessUpgradeRequestsController < ApplicationController
  # POST /business_upgrade_requests
  def create
    if current_user.account_type == "business"
      return render json: { error: "Your account is already a business account." }, status: :unprocessable_entity
    end

    existing = BusinessUpgradeRequest.where(user_id: current_user.id, request_status: %w[pending approved]).first
    if existing
      return render json: {
        error: "You already have an active upgrade request.",
        request_status: existing.request_status
      }, status: :unprocessable_entity
    end

    upgrade_request = BusinessUpgradeRequest.new(
      user:           current_user,
      request_status: "pending",
      requested_at:   Time.current
    )

    if upgrade_request.save
      render json: {
        message: "Your upgrade request has been submitted. An admin will review it shortly.",
        upgrade_request: serialize_request(upgrade_request)
      }, status: :created
    else
      render json: { errors: upgrade_request.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /business_upgrade_requests/status
  def status
    req = BusinessUpgradeRequest.where(user_id: current_user.id).order(created_at: :desc).first

    render json: { upgrade_request: req ? serialize_request(req) : nil }, status: :ok
  end

  private

  def serialize_request(req)
    {
      id:               req.id,
      request_status:   req.request_status,
      requested_at:     req.requested_at,
      approved_at:      req.approved_at,
      rejection_reason: req.rejection_reason
    }
  end
end
