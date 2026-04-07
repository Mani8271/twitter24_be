class OfferSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id,
             :title,
             :description,
             :offer_type,
             :latitude,
             :longitude,
             :address,
             :reach_distance,
             :valid_till,
             :tags,
             :disappearing_days,
             :links,
             :media,
             :created_at,
             :user_id,
             :poster_name,
             :poster_avatar

  def media
    return [] unless object.media.attached?
    object.media.map do |attachment|
      {
        url:          rails_blob_url(attachment),
        content_type: attachment.content_type
      }
    end
  end

  def poster_name
    user = object.user
    user.account_type == "business" ? user.business&.name : user.name
  end

  def poster_avatar
    return nil unless object.user.profile_picture.attached?
    rails_blob_url(object.user.profile_picture)
  rescue
    nil
  end
end