class ViewsController < ApplicationController
  before_action :authorize_request

  # FIXED: Explicit type mapping instead of constantize
  VIEWABLE_TYPES = {
    "GlobalFeed" => GlobalFeed,
    "Job" => Job,
    "Offer" => Offer
  }.freeze

  def create
    viewable = find_viewable
    return if viewable.nil?

    unless viewable.respond_to?(:user_id) && viewable.user_id == current_user.id
      viewable.views.find_or_create_by!(user: current_user)
    end

    head :ok
  end

  private

  def find_viewable
    type = params.require(:viewable_type)
    id   = params.require(:viewable_id)

    # FIXED: Use explicit type mapping instead of constantize
    klass = VIEWABLE_TYPES[type]

    unless klass
      render json: { error: "Invalid viewable type" }, status: :bad_request
      return nil
    end

    begin
      klass.find(id)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "#{type} not found" }, status: :not_found
      nil
    end
  end
end
