class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  before_action :authorize_request, unless: :skip_jwt_auth?

  # Dynamically set URL host from the actual incoming request.
  # This ensures ActiveStorage URLs always match the server being hit
  # (ngrok in dev, render.com in prod) — no hardcoded host needed.
  before_action :set_default_url_host

  def set_default_url_host
    Rails.application.routes.default_url_options[:host]     = request.host_with_port
    Rails.application.routes.default_url_options[:protocol] = request.protocol.chomp("://")
    ActiveStorage::Current.url_options = { host: request.host_with_port, protocol: request.protocol.chomp("://") }
  end

  attr_reader :current_user

  def not_found
    render json: { error: "not_found" }, status: :not_found
  end

  private

  # ✅ skip JWT for admin/devise/activeadmin and non-API HTML pages
  def skip_jwt_auth?
    request.path.start_with?("/admin") ||
      devise_controller? ||
      (request.format.html? && !request.path.start_with?("/global_feeds"))
  end

  def authorize_request
    header = request.headers["Authorization"]
    token = header.split(" ").last if header.present?

    # ✅ token missing => return clean error (instead of nil decode crash)
    if token.blank?
      return render json: { errors: "Missing token" }, status: :unauthorized
    end

    decoded = JsonWebToken.decode(token)
    @current_user = User.find(decoded[:user_id])
  rescue ActiveRecord::RecordNotFound => e
    render json: { errors: e.message }, status: :unauthorized
  rescue JWT::DecodeError => e
    render json: { errors: e.message }, status: :unauthorized
  rescue StandardError
    render json: { errors: "Unauthorized" }, status: :unauthorized
  end
end
