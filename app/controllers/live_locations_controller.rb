class LiveLocationsController < ApplicationController
  before_action :authorize_request

  # POST /live_location
  # body: { latitude, longitude, live_location_default(optional) }
  def upsert
    lat = params[:latitude]
    lng = params[:longitude]
    return render json: { error: "latitude and longitude required" }, status: :bad_request if lat.blank? || lng.blank?

    # ✅ if you currently have has_one :live_location
    loc = current_user.live_location || current_user.build_live_location

    loc.latitude = lat
    loc.longitude = lng

    # ✅ default param handling
    want_default = ActiveModel::Type::Boolean.new.cast(params[:live_location_default])

    # If this user has no saved live_location yet, make first one default
    is_new_record = loc.new_record?
    loc.live_location_default = true if is_new_record

    # If client explicitly asks default=true, set it true
    loc.live_location_default = true if want_default

    # ✅ force reverse geocode now
    loc.reverse_geocode
    loc.save!

    # ✅ If default=true, ensure only one default per user (useful if you later move to has_many)
    if loc.live_location_default
      LiveLocation.where(user_id: current_user.id)
                  .where.not(id: loc.id)
                  .update_all(live_location_default: false)
    end

    render json: { message: "Location updated", live_location: loc_response(loc) }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # GET /live_location/me
  def me
    loc = current_user.live_location
    render json: { live_location: loc ? loc_response(loc) : nil }, status: :ok
  end

  # GET /live_location/reach_counts?latitude=..&longitude=..
  def reach_counts
    lat = params[:latitude]
    lng = params[:longitude]
    return render json: { error: "latitude and longitude required" }, status: :bad_request if lat.blank? || lng.blank?

    ranges = [5, 10, 15, 20, 25, 30, 35, 40, 50]

    base = LiveLocation.where.not(latitude: nil, longitude: nil)
                       .where.not(user_id: current_user.id)

    data = ranges.map do |km|
      count = base.near([lat.to_f, lng.to_f], km).count
      { km: km, total: count }
    end

    render json: { data: data }, status: :ok
  end

  private

  def loc_response(loc)
    {
      id: loc.id,
      user_id: loc.user_id,
      latitude: loc.latitude,
      longitude: loc.longitude,
      address: loc.address,
      city: loc.city,
      state: loc.state,
      country: loc.country,
      live_location_default: loc.live_location_default 
    }
  end
end
