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
             :posted_by,
             :business,
             :media,
             :created_at

  # =========================
  # COUNTS
  # =========================
  def likes_count
    object.likes.count
  end

  def comments_count
    object.comments.count
  end

  def views_count
    object.views.count
  end

  def liked_by_me
    scope && object.likes.exists?(user_id: scope.id)
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
   profile_picture: biz.profile_picture.attached? ? rails_blob_url(biz.profile_picture) : nil
  }
end


  # =========================
  # MEDIA
  # =========================
 def media
  object.media.map do |file|
    {
      id: file.id,
      url: rails_blob_url(file),
      content_type: file.content_type
    }
  end
end
end
