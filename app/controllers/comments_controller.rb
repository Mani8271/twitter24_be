class CommentsController < ApplicationController
  before_action :authorize_request

  def index
    commentable = find_commentable

    comments = commentable.comments
                          .where(parent_id: nil)
                          .includes(:user, replies: :user)

    render json: comments.map { |c| serialize_comment(c) }
  end

  def create
    commentable = find_commentable

    comment = commentable.comments.new(
      body: params[:body],
      parent_id: params[:parent_id],
      user: current_user
    )

    if comment.save
      render json: serialize_comment(comment), status: :created
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

  def serialize_comment(comment)
    {
      id: comment.id,
      user_id: comment.user_id,
      body: comment.body,
      parent_id: comment.parent_id,
      created_at: comment.created_at,
      updated_at: comment.updated_at,
      user: {
        id: comment.user.id,
        name: comment.user.name
      },
      replies: comment.replies.map { |r| serialize_comment(r) }
    }
  end
end
