# app/serializers/business_serializer.rb
class BusinessSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id,
             :user_id,
             :name,
             :category,
             :keywords,
             :video_links,
             :about,
             :year_established,
             :website,
             :products_services,
             :rating,
             :reviews_count,
             :followers_count,
             :is_online,
             :jobs_count,
             :followed_by_me,
             :global_feeds_count,
             :local_feeds_count,
             :is_open,
             :is_online,
             :open_days,
             :open_time,
             :business_hours_schedule,
             :phone,
             :address,
             :distance_km,
             :images,
             :favorites_count,
             :favorited_by_me

  # =================================
  # COUNTS
  # =================================
  def rating
    object.average_rating || 0
  end

  def jobs_count
    object.user.jobs.size
  end

  def reviews_count
    object.reviews_count || 0
  end

  def followers_count
    object.follows.size
  end

  def followed_by_me
    return false unless scope
    if object.association(:follows).loaded?
      object.follows.any? { |f| f.user_id == scope.id }
    else
      object.follows.exists?(user_id: scope.id)
    end
  end

  def global_feeds_count
    if object.association(:global_feeds).loaded?
      object.global_feeds.count { |f| f.feed_type == "global" }
    else
      object.global_feeds.where(feed_type: "global").count
    end
  end

  def local_feeds_count
    if object.association(:global_feeds).loaded?
      object.global_feeds.count { |f| f.feed_type == "local" }
    else
      object.global_feeds.where(feed_type: "local").count
    end
  end

  # =================================
  # OPEN / CLOSED LOGIC
  # =================================
  def is_open
    today = object.business_hours.find { |h| h.day_of_week == Time.current.wday }
    return false unless today&.is_open

    now_time = Time.current.strftime("%H:%M")
    now_time >= today.opens_at.strftime("%H:%M") &&
      now_time <= today.closes_at.strftime("%H:%M")
  end

  def open_days
    days = %w[Sun Mon Tue Wed Thu Fri Sat]
    object.business_hours.select(&:is_open).map { |h| days[h.day_of_week] }.join(", ")
  end

  def open_time
    today = object.business_hours.find { |h| h.day_of_week == Time.current.wday }
    return nil unless today

    "#{today.opens_at.strftime('%I:%M %p')} - #{today.closes_at.strftime('%I:%M %p')}"
  end

  def business_hours_schedule
    day_names = %w[Sun Mon Tue Wed Thu Fri Sat]
    object.business_hours.sort_by(&:day_of_week).map do |h|
      {
        day:       day_names[h.day_of_week],
        is_open:   h.is_open,
        opens_at:  h.is_open && h.opens_at  ? h.opens_at.strftime('%I:%M %p')  : nil,
        closes_at: h.is_open && h.closes_at ? h.closes_at.strftime('%I:%M %p') : nil,
      }
    end
  end

  # =================================
  # PHONE / ADDRESS / DISTANCE
  # =================================
  def phone
    object.business_contact&.contact_phone
  end

  def address
    loc = object.business_location
    return nil unless loc

    [loc.address_line1, loc.city, loc.state].compact.join(", ")
  end

  def distance_km
    return 0 unless scope  # scope is current_user

    loc = object.business_location
    return 0 unless loc&.latitude && loc&.longitude

    # Use detect (in-memory) when live_locations is preloaded; find_by otherwise.
    # Controllers should call current_user.live_locations.load before serializing
    # a list so this fires at most one query per request, not one per business.
    user_loc = if scope.live_locations.loaded?
                 scope.live_locations.detect(&:live_location_default)
               else
                 scope.live_locations.find_by(live_location_default: true)
               end

    return 0 unless user_loc&.latitude && user_loc&.longitude

    Geocoder::Calculations.distance_between(
      [user_loc.latitude, user_loc.longitude],
      [loc.latitude, loc.longitude]
    ).round(2)
  end

  # =================================
  # IMAGES
  # =================================
  def images
    return {} unless object.profile_picture.attached? || object.shop_images.attached?

    {
      profile_picture: object.profile_picture.attached? ? object.profile_picture.blob.url : nil,

      gallery: object.shop_images.map do |img|
        { id: img.blob.id, url: img.blob.url }
      end
    }
  end
  
  

  def favorites_count
    object.likes.size
  end

  def favorited_by_me
    return false unless scope
    if object.association(:likes).loaded?
      object.likes.any? { |l| l.user_id == scope.id }
    else
      object.likes.exists?(user_id: scope.id)
    end
  end
end
