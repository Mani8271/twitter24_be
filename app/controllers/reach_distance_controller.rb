class ReachDistanceController < ApplicationController
  before_action :authorize_request

  # GET /api/reach_distance/summary
  def summary
    # 1) Business default live location (origin)
    default_address = @current_user.live_locations.find_by(live_location_default: true)

    unless default_address&.latitude.present? && default_address&.longitude.present?
      return render json: { message: "Business default live location not found" }, status: 422
    end

    origin = [default_address.latitude, default_address.longitude]

    # 2) Ranges from ActiveAdmin settings (global single row)
    setting = ReachDistanceSetting.first
    ranges  = setting&.is_active ? setting.ranges_array : []
    ranges  = ranges.presence || [5, 10, 15, 20, 25]   # fallback

    ranges = ranges.map(&:to_f).select { |x| x > 0 }.uniq.sort
    max_km = ranges.max

    # 3) Fetch all user live_locations within max range (ONE query)
    nearby = LiveLocation
      .joins(:user)
      .where(users: { account_type: "user" })
      .where.not(latitude: nil, longitude: nil)
      # .where(users: { is_online: true }) # uncomment if only online users needed
      .near(origin, max_km, units: :km)
     

    # 4) Unique per user (pick nearest location per user)
    min_dist_by_user = {}
    nearby.each do |loc|
      uid = loc.user_id
      d   = loc.distance.to_f # geocoder adds this
      min_dist_by_user[uid] = d if !min_dist_by_user.key?(uid) || d < min_dist_by_user[uid]
    end

    distances = min_dist_by_user.values

    result = ranges.map do |km|
      { km: km, count: distances.count { |d| d <= km } }
    end

    render json: {
      origin: {
        latitude: default_address.latitude,
        longitude: default_address.longitude,
        address: default_address.address
      },
      ranges: result,
      total_within_max: distances.size
    }
  end
end
