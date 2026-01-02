class ApplicationController < ActionController::Base
  # For APIs (Postman / Mobile) -> no CSRF token needed
  # This prevents "InvalidAuthenticityToken" on JSON requests.
  protect_from_forgery with: :null_session

  # Optional: only for JSON requests (recommended if you have HTML pages)
  # protect_from_forgery with: :null_session, if: -> { request.format.json? }

  before_action :authorize_request

  attr_reader :current_user

  def not_found
    render json: { error: "not_found" }, status: :not_found
  end

  private

  def authorize_request
    header = request.headers["Authorization"]
    token = header.split(" ").last if header.present?

    @decoded = JsonWebToken.decode(token)
    @current_user = User.find(@decoded[:user_id])
  rescue ActiveRecord::RecordNotFound => e
    render json: { errors: e.message }, status: :unauthorized
  rescue JWT::DecodeError => e
    render json: { errors: e.message }, status: :unauthorized
  rescue StandardError
    render json: { errors: "Unauthorized" }, status: :unauthorized
  end
end
