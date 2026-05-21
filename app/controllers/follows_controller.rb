class FollowsController < ApplicationController
  before_action :authorize_request
  before_action :set_followable

  def create
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
    allowed_types = %w[Business]

    type = params[:followable_type]
    raise ActiveRecord::RecordNotFound unless allowed_types.include?(type)

    @followable = type.constantize.find(params[:followable_id])
  end
end
