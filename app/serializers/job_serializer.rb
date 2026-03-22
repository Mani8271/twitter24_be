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
             :image_url,
             :created_at,
             :updated_at

  def is_my_post
    scope&.id == object.user_id
  end

  def salary
    object.salary&.to_s
  end

  def image_url
    return nil unless object.image.attached?
    rails_blob_url(object.image, host: ENV["APP_HOST"] || "https://twitter24-be.onrender.com")
  end
end
