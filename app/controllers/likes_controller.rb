class LikesController < ApplicationController
  before_action :authorize_request
  before_action :set_likeable

  # FIXED: Explicit type mapping instead of constantize
  LIKEABLE_TYPES = {
    "GlobalFeed" => GlobalFeed,
    "Business" => Business,
    "Job" => Job,
    "Offer" => Offer
  }.freeze

  def create
    return if @likeable.nil?

    # Prevent liking own content
    if @likeable.respond_to?(:user_id) && @likeable.user_id == current_user.id
      return render json: { error: "You cannot like your own content" }, status: :forbidden
    end

    like = @likeable.likes.find_by(user: current_user)

    if like
      like.destroy
      liked = false
    else
      @likeable.likes.create!(user: current_user)
      liked = true
    end

    render json: {
      liked: liked,
      likes_count: @likeable.likes.count
    }
  end

  private

  def set_likeable
    type = params[:likeable_type]
    likeable_id = params[:likeable_id]

    # FIXED: Use explicit type mapping instead of constantize
    klass = LIKEABLE_TYPES[type]

    unless klass
      render json: { error: "Invalid likeable type" }, status: :bad_request
      return nil
    end

    begin
      @likeable = klass.find(likeable_id)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "#{type} not found" }, status: :not_found
      nil
    end
  end
end
