class CommentsController < ApplicationController
  before_action :authorize_request

  # FIXED: Explicit type mapping instead of constantize
  COMMENTABLE_TYPES = {
    "GlobalFeed" => GlobalFeed,
    "Offer" => Offer,
    "Job" => Job
  }.freeze

  def index
    commentable = find_commentable

    comments = commentable.comments
                          .where(parent_id: nil)
                          .includes(:user, replies: :user)

    render json: comments, each_serializer: CommentSerializer, scope: current_user
  end

  def create
    commentable = find_commentable

    comment = commentable.comments.new(
      body: params[:body],
      parent_id: params[:parent_id],
      user: current_user
    )

    if comment.save
      comment = Comment.includes(:user, replies: :user).find(comment.id)
      render json: comment, serializer: CommentSerializer, scope: current_user, status: :created
    else
      render json: { errors: comment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    comment = Comment.find(params[:id])

    return render json: { error: "Not authorized" }, status: :forbidden if comment.user_id != current_user.id

    comment.destroy
    render json: { message: "Comment deleted" }
  end

  private

  def find_commentable
    type = params.require(:commentable_type)
    id   = params.require(:commentable_id)

    # FIXED: Use explicit type mapping instead of constantize
    klass = COMMENTABLE_TYPES[type]

    unless klass
      render json: { error: "Invalid commentable type" }, status: :bad_request
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
