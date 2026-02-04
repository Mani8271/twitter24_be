class LikesController < ApplicationController
  before_action :authorize_request
  before_action :set_likeable

  def create
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
    allowed_types = %w[GlobalFeed FreedCrate]

    type = params[:likeable_type]
    raise ActiveRecord::RecordNotFound unless allowed_types.include?(type)

    @likeable = type.constantize.find(params[:likeable_id])
  end
end
