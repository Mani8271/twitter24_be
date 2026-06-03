class LegalController < ApplicationController
  skip_before_action :authorize_request

  # GET /legal/terms
  def terms
    record = Content.find_by(title: "terms_and_conditions")
    if record&.content.present?
      render json: { html: record.content }, status: :ok
    else
      render json: { html: "" }, status: :ok
    end
  end

  # GET /legal/privacy-policy
  def privacy_policy
    record = Content.find_by(title: "privacy_policy")
    if record&.content.present?
      render json: { html: record.content }, status: :ok
    else
      render json: { html: "" }, status: :ok
    end
  end

  # GET /legal/cancellation-refund-policy
  def cancellation_refund_policy
    record = Content.find_by(title: "cancellation_refund_policy")
    if record&.content.present?
      render json: { html: record.content }, status: :ok
    else
      render json: { html: "" }, status: :ok
    end
  end
end
