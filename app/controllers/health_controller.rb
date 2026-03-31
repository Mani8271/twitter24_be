class HealthController < ApplicationController
  skip_before_action :authorize_request
  skip_before_action :set_default_url_host

  def show
    render json: { status: "ok" }, status: :ok
  end
end
