class BusinessesController < ApplicationController
  before_action :authorize_request
  before_action :set_user_location

  # =========================================================
  # 🟣 DISCOVER LIST API
  # GET /api/v1/businesses
  # =========================================================
  def index
    businesses = Business
      .includes(:business_location, :business_hours, :business_contact,
                profile_picture_attachment: :blob)
      .where(status: "approved")

    render json: businesses.map { |b| business_card_json(b) }, status: :ok
  end

  # =========================================================
  # 🔵 BUSINESS DETAIL PAGE
  # GET /api/v1/businesses/:id
  # =========================================================
  def show
    business = Business.includes(
      :business_location,
      :business_contact,
      :business_hours,
      shop_images_attachments: :blob,
      profile_picture_attachment: :blob
    ).find(params[:id])

    render json: business_detail_json(business), status: :ok
  end

  private

  # =========================================================
  # 📍 USER LOCATION
  # =========================================================
  def set_user_location
    @user_location = current_user.live_locations.find_by(live_location_default: true)
  end

  # =========================================================
  # 🟣 LIST CARD JSON
  # =========================================================
  def business_card_json(business)
    {
      id: business.id,
      name: business.name,
      category: business.category,
      rating: business.average_rating || 0,
       reviews_count: business.reviews_count || 0,
      is_open: open_now?(business),
      distance_km: distance_from_user(business),
      address: full_address(business),
      image: business.profile_picture.attached? ? url_for(business.profile_picture) : nil
    }
  end

  # =========================================================
  # 🔵 DETAIL PAGE JSON
  # =========================================================
  def business_detail_json(business)
    {
      id: business.id,
      name: business.name,
      category: business.category,
      about: business.about,
      year_established: business.year_established,
      website: business.website,
      products_services: business.products_services,
      rating: business.average_rating || 0,
      reviews_count: business.reviews_count || 0,
      followers_count: 526,

      is_open: open_now?(business),
      open_days: open_days_text(business),
      open_time: open_time_text(business),

      phone: business.business_contact&.contact_phone,
      address: full_address(business),
      distance_km: distance_from_user(business),

      images: {
        profile_picture: business.profile_picture.attached? ? url_for(business.profile_picture) : nil,
        gallery: business.shop_images.map { |img| url_for(img) }
      }
    }
  end

  # =========================================================
  # 🕒 OPEN / CLOSED LOGIC
  # =========================================================
  def open_now?(business)
    now = Time.current
    today = business.business_hours.find { |h| h.day_of_week == now.wday }
    return false unless today&.is_open

    now_time = now.strftime("%H:%M")
    now_time >= today.opens_at.strftime("%H:%M") &&
      now_time <= today.closes_at.strftime("%H:%M")
  end

  def open_days_text(business)
    days = %w[Sun Mon Tue Wed Thu Fri Sat]
    business.business_hours
            .select(&:is_open)
            .map { |h| days[h.day_of_week] }
            .join(", ")
  end

  def open_time_text(business)
    today = business.business_hours.find { |h| h.day_of_week == Time.current.wday }
    return nil unless today
    "#{today.opens_at.strftime('%I:%M %p')} - #{today.closes_at.strftime('%I:%M %p')}"
  end

  # =========================================================
  # 📏 DISTANCE
  # =========================================================
  def distance_from_user(business)
    return 0 unless @user_location

    loc = business.business_location
    return 0 unless loc&.latitude && loc&.longitude

    Geocoder::Calculations.distance_between(
      [@user_location.latitude, @user_location.longitude],
      [loc.latitude, loc.longitude]
    ).round(2)
  end

  # =========================================================
  # 📍 ADDRESS
  # =========================================================
  def full_address(business)
    loc = business.business_location
    return nil unless loc

    [
      loc.address_line1,
      loc.city,
      loc.state
    ].compact.join(", ")
  end
end
