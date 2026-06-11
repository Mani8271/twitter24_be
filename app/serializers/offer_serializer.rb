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
             :valid_from,
             :valid_till,
             :tags,
             :disappearing_days,
             :links,
             :media,
             :created_at,
             :user_id,
             :is_my_post,
             :is_own_post,
             :business,
             :created_user

  def is_my_post
    scope&.id == object.user_id
  end

  def is_own_post
    scope&.id == object.user_id
  end

  def business
    return nil unless object.user.account_type == "business"
    biz = object.user.business
    return nil unless biz
    {
      id:              biz.id,
      name:            biz.name,
      category:        biz.category,
      address:         biz.business_location&.map_address || biz.business_location&.city,
      profile_picture: biz.profile_picture.attached? ? biz.profile_picture.blob.url(expires_in: 7.days) : nil
    }
  rescue
    nil
  end

  def created_user
    user = object.user
    return nil unless user
    {
      id:              user.id,
      name:            user.name,
      profile_picture: user.profile_picture.attached? ? user.profile_picture.blob.url(expires_in: 7.days) : nil
    }
  rescue
    nil
  end

  def media
    return [] unless object.media.attached?
    object.media.map do |attachment|
      {
        url:          attachment.blob.url(expires_in: 7.days),
        content_type: attachment.content_type
      }
    end
  end
end
