class GlobalFeedSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id,
             :user_id,
             :feed_type,
             :title,
             :description,
             :category,
             :tags,
             :links,
             :disappear_after,
             :latitude,
             :longitude,
             :address,
             :reach_distance,
             :likes_count,
             :comments_count,
             :views_count,
             :liked_by_me,
             :is_own_post,
             :posted_by,
             :business,
             :media,
             :created_at,
             :created_user

  # =========================
  # COUNTS
  # =========================
  def likes_count
    object.likes.size
  end

  def comments_count
    object.comments.size
  end

  def views_count
    object.views.size
  end

  def liked_by_me
    return false unless scope
    if object.association(:likes).loaded?
      object.likes.any? { |l| l.user_id == scope.id }
    else
      object.likes.exists?(user_id: scope.id)
    end
  end

  def is_own_post
    return false unless scope
    object.user_id == scope.id
  end

  # =========================
  # USER / BUSINESS
  # =========================
  def posted_by
    object.user.account_type
  end

  def business
    return nil unless object.user.account_type == "business"

    biz = object.user.business
    return nil unless biz

    {
      id: biz.id,
      name: biz.name,
      category: biz.category,
      address: biz.business_location&.map_address || biz.business_location&.city,
      profile_picture: biz.profile_picture.attached? ? biz.profile_picture.blob.url(expires_in: 7.days) : nil
    }
  end


def created_user
  user = object.user
  return nil unless user

  {
    id: user.id,
    name: user.name,
    profile_picture: user.profile_picture.attached? ? user.profile_picture.blob.url(expires_in: 7.days) : nil
  }
end



  # =========================
  # MEDIA
  # =========================
 def media
  object.media.map do |file|
    {
      id: file.id,
        url: file.blob.url(expires_in: 7.days),
      content_type: file.content_type
    }
  end
end
end
