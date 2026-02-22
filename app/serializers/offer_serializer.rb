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
             :media_url,
             :created_at,
             :user_id

  def media_url
    return nil unless object.media.attached?
    rails_blob_url(object.media)
  end
end