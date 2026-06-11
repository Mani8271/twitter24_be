class JobSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id,
             :location_name,
             :latitude,
             :longitude,
             :reach_distance,
             :job_title,
             :salary,
             :experience,
             :job_type,
             :working_hours,
             :description,
             :skills_required,
             :links,
             :tags,
             :disappearing_days,
             :user_id,
             :is_my_post,
             :is_own_post,
             :business,
             :created_user,
             :image_urls,
             :created_at,
             :updated_at

  def is_my_post
    scope&.id == object.user_id
  end

  def is_own_post
    scope&.id == object.user_id
  end

  def salary
    object.salary&.to_s
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

  def image_urls
    return [] unless object.images.attached?
    object.images.map do |img|
      img.blob.url(expires_in: 7.days)
    end
  end
end
