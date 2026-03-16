class JobSerializer < ActiveModel::Serializer
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
             :created_at,
             :updated_at

  def is_my_post
    scope&.id == object.user_id
  end
end
