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
             :offers_count,
             :followed_by_me,
             :global_feeds_count,
             :local_feeds_count,
             :is_open,
             :open_days,
             :open_time,
             :business_hours_schedule,
             :phone,
             :address,
             :distance_km,
             :images,
             :favorites_count,
             :favorited_by_me,
             :is_own_business,
             :address_cooldown_active,
             :next_address_update_date,
             :days_until_next_address_update,
             :address_last_updated_at

  # =================================
  # COUNTS
  # =================================
  def rating
    object.average_rating || 0
  end

  def jobs_count
    object.user.jobs.size || 0
  end

  def offers_count
    object.user.offers.size || 0
  end

  def reviews_count
    object.reviews_count || 0
  end

  def followers_count
    object.follows.size || 0
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

    # Prefer live GPS coordinates passed by the client via instance_options.
    # Falls back to the DB-stored live_location so list views still work
    # without requiring the client to append coords to every request.
    override_lat = instance_options[:user_lat]
    override_lng = instance_options[:user_lng]

    if override_lat && override_lng
      user_lat = override_lat
      user_lng = override_lng
    else
      # Use detect (in-memory) when live_locations is preloaded; find_by otherwise.
      # Controllers should call current_user.live_locations.load before serializing
      # a list so this fires at most one query per request, not one per business.
      user_loc = if scope.live_locations.loaded?
                   scope.live_locations.detect(&:live_location_default)
                 else
                   scope.live_locations.find_by(live_location_default: true)
                 end
      return 0 unless user_loc&.latitude && user_loc&.longitude
      user_lat = user_loc.latitude
      user_lng = user_loc.longitude
    end

    Geocoder::Calculations.distance_between(
      [user_lat, user_lng],
      [loc.latitude, loc.longitude]
    ).round(2)
  end

  # =================================
  # IMAGES
  # =================================
  def images
    has_pp   = object.profile_picture.attached?
    has_shop = object.shop_images.attached?
    return {} unless has_pp || has_shop

    {
      profile_picture: has_pp ? attachment_url(object.profile_picture) : nil,
      gallery: has_shop ? object.shop_images.map { |img| { id: img.blob.id, url: img.blob.url(expires_in: 7.days) } } : []
    }
  end



  def is_own_business
    return false unless scope
    object.user_id == scope.id
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

  # =================================
  # ADDRESS COOLDOWN
  # =================================
  def address_cooldown_active
    return false unless object.business_location
    object.business_location.address_cooldown_active?
  end

  def next_address_update_date
    return nil unless object.business_location
    object.business_location.next_address_update_date&.strftime("%d %B %Y")
  end

  def days_until_next_address_update
    return 0 unless object.business_location
    object.business_location.days_until_next_address_update
  end

  def address_last_updated_at
    return nil unless object.business_location
    object.business_location.address_last_updated_at
  end

  private

  def attachment_url(attachment)
    return nil unless attachment&.attached?
    attachment.blob.url(expires_in: 7.days)
  rescue StandardError
    nil
  end
end
