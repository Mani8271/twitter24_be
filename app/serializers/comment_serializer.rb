class CommentSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id,
             :body,
             :parent_id,
             :commentable_type,
             :commentable_id,
             :created_at,
             :updated_at,
             :user,
             :replies_count,
             :comment_by_me

  has_many :replies, serializer: CommentSerializer

  def user
    u = object.user
    {
      id: u.id,
      name: u.name,
      profile_picture: u.profile_picture.attached? ? u.profile_picture.blob.url(expires_in: 7.days) : nil
    }
  end

  def replies_count
    object.replies.count
  end

  def comment_by_me
    scope && object.user_id == scope.id
  end
end
