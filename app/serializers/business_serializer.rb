# app/serializers/business_serializer.rb
class BusinessSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id,
             :name,
             :category,
             :about,
             :year_established,
             :website,
             :products_services,
             :rating,
             :reviews_count,
             :followers_count,
             :followed_by_me,
             :global_feeds_count,
             :local_feeds_count,
             :is_open,
             :open_days,
             :open_time,
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

  def reviews_count
    object.reviews_count || 0
  end

 def followers_count
  object.followers_count
end

def followed_by_me
  scope && object.followed_by?(scope)
end
  def global_feeds_count
    object.global_feeds.where(feed_type: "global").count
  end

  def local_feeds_count
    object.global_feeds.where(feed_type: "local").count
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

    Geocoder::Calculations.distance_between(
      [scope.live_locations.find_by(live_location_default: true)&.latitude, 
       scope.live_locations.find_by(live_location_default: true)&.longitude],
      [loc.latitude, loc.longitude]
    ).round(2)
  end

  # =================================
  # IMAGES
  # =================================
  def images
    return {} unless object.profile_picture.attached? || object.shop_images.attached?
  
    {
      profile_picture: object.profile_picture.attached? ? url_for(object.profile_picture) : nil,
      gallery: object.shop_images.map { |img| url_for(img) }
    }
  end
  

   def favorites_count
    object.favorites_count
  end

  def favorited_by_me
    scope && object.favorited_by?(scope)
  end
end
