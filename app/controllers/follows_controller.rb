class FollowsController < ApplicationController
  before_action :authorize_request
  before_action :set_followable

  # FIXED: Explicit type mapping instead of constantize
  FOLLOWABLE_TYPES = {
    "Business" => Business,
    "User" => User
  }.freeze

  def create
    return if @followable.nil?

    # Prevent following own business
    if @followable.respond_to?(:user_id) && @followable.user_id == current_user.id
      return render json: { error: "You cannot follow your own business" }, status: :forbidden
    end

    follow = @followable.follows.find_by(user: current_user)

    if follow
      follow.destroy
      followed = false
    else
      @followable.follows.create!(user: current_user)
      followed = true
    end

    render json: {
      followed: followed,
      followers_count: @followable.follows.count
    }
  end

  private

  def set_followable
    type = params[:followable_type]
    followable_id = params[:followable_id]

    # FIXED: Use explicit type mapping instead of constantize
    klass = FOLLOWABLE_TYPES[type]

    unless klass
      render json: { error: "Invalid followable type" }, status: :bad_request
      return nil
    end

    begin
      @followable = klass.find(followable_id)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "#{type} not found" }, status: :not_found
      nil
    end
  end
end
