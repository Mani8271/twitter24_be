class CommentsController < ApplicationController
  before_action :authorize_request

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
    allowed_types = %w[GlobalFeed FreedCrate]

    type = params.require(:commentable_type)
    id   = params.require(:commentable_id)

    raise ActiveRecord::RecordNotFound unless allowed_types.include?(type)

    type.constantize.find(id)
  end
end
