
class BusinessesController < ApplicationController
  before_action :authorize_request
  before_action :set_user_location

  # =========================================================
  # 🟣 DISCOVER LIST API
  # GET /api/v1/businesses
  # =========================================================
   def index
  # Preload current_user's live location once so BusinessSerializer#distance_km
  # can use detect (in-memory) instead of firing a find_by per business.
  current_user.live_locations.load

  businesses = Business
                .includes(
                  :business_location, :business_hours, :business_contact,
                  :follows, :likes, :global_feeds,
                  { user: [:jobs, :offers] },
                  profile_picture_attachment: :blob
                )
                .where(status: "approved")
                if params[:mine].to_s.downcase == "true"
                  businesses = businesses.where(user_id: current_user.id)
                else
                  businesses = businesses.where.not(user_id: current_user.id)
                end
  # ✅ Filter for favorites if query param is present
  if params[:favourites].to_s.downcase == "true"
    businesses = businesses.joins(:likes)
                           .where(likes: { user_id: current_user.id })
  end

  # ✅ Filter by category
  if params[:categories].present?
    cats = params[:categories].split(",").map(&:strip).reject(&:blank?)
    businesses = businesses.where(category: cats) if cats.any?
  end

  # ✅ Search by name / category / about
  if params[:search].present?
    q = "%#{params[:search].downcase}%"
    businesses = businesses.where(
      "LOWER(businesses.name) LIKE :q OR LOWER(businesses.category) LIKE :q OR LOWER(businesses.about) LIKE :q",
      q: q
    )
  end

  # ✅ Sort
  case params[:sort]
  when "newest_first"  then businesses = businesses.order(created_at: :desc)
  when "oldest_first"  then businesses = businesses.order(created_at: :asc)
  when "most_popular"
    # FIXED: Avoid subquery for sorting since we already loaded follows
    # Convert to Array and sort in Ruby for the loaded associations
    businesses = businesses.order(created_at: :desc)  # Fallback order
    businesses = businesses.to_a.sort_by { |b| -b.follows.size }  # Sort by follows count
  end

  render json: businesses,
         each_serializer: BusinessSerializer,
         scope: current_user
end

def update
  business = Business.find_by(id: params[:id], user_id: current_user.id)
  return render json: { error: "Business not found" }, status: :not_found unless business

  if business.update(business_params)
    render json: business,
           serializer: BusinessSerializer,
           scope: current_user
  else
    render json: { errors: business.errors.full_messages },
           status: :unprocessable_entity
  end
end

# =========================================================
# 🔗 RELATED BUSINESSES (WITH LOCATION-BASED FILTERING)
# GET /businesses/:id/related
# =========================================================
# Returns nearby approved businesses filtered by:
# - Geographic proximity (Haversine distance)
# - Approval status (only "approved" businesses)
# - Category relevance (same category first, then others)
# - Exclusions: current business, user's own businesses
# - Sorted by: distance (nearest first), then category relevance, then popularity
#
# Query parameters:
#   - lat (optional): User's current latitude (for distance calculation)
#   - lng (optional): User's current longitude (for distance calculation)
#   - limit (optional): Max results to return (default: 6)
# =========================================================
def related
  # Pre-load user's live locations for efficient access
  current_user.live_locations.load

  # Load the business being viewed and its location
  business = Business.includes(:business_location).find(params[:id])
  business_loc = business.business_location

  # Return empty array if the business has no location data
  return render json: [] unless business_loc&.latitude && business_loc&.longitude

  # Determine distance calculation starting point: prefer client coords, then DB coords
  reference_lat = params[:lat]&.to_f
  reference_lng = params[:lng]&.to_f

  unless reference_lat && reference_lng
    user_loc = current_user.live_locations.loaded? ?
               current_user.live_locations.detect(&:live_location_default) :
               current_user.live_locations.find_by(live_location_default: true)
    reference_lat = user_loc&.latitude
    reference_lng = user_loc&.longitude
  end

  # Configuration for radius filtering (in kilometers)
  same_category_radius = ENV.fetch("RELATED_BUSINESSES_SAME_CAT_RADIUS_KM", "25").to_f
  other_category_radius = ENV.fetch("RELATED_BUSINESSES_OTHER_CAT_RADIUS_KM", "50").to_f
  max_results = params[:limit].to_i.positive? ? params[:limit].to_i : 6

  excluded_ids = [business.id]
  result_ids = Set.new
  final_results = []

  # Helper lambda to calculate Haversine distance between two points
  calc_distance = lambda do |lat1, lng1, lat2, lng2|
    next nil unless lat1 && lng1 && lat2 && lng2
    Geocoder::Calculations.distance_between([lat1, lng1], [lat2, lng2])
  end

  # =========================================================
  # STEP 1: Same-category approved businesses within radius
  # =========================================================
  same_cat_candidates = Business
    .includes(:business_location, :business_hours, :business_contact,
              profile_picture_attachment: :blob)
    .where(status: "approved")
    .where(category: business.category)
    .where.not(id: excluded_ids)
    .where.not(user_id: current_user.id)
    .joins(:business_location)

  same_cat_with_distance = []
  same_cat_candidates.each do |candidate|
    candidate_loc = candidate.business_location
    # Skip if candidate has missing/invalid coordinates
    next unless candidate_loc&.latitude && candidate_loc&.longitude

    # Calculate distance from the viewed business to candidate
    distance = calc_distance.call(
      business_loc.latitude, business_loc.longitude,
      candidate_loc.latitude, candidate_loc.longitude
    )

    # Include if within same-category radius
    if distance && distance <= same_category_radius
      same_cat_with_distance << {
        biz: candidate,
        distance: distance,
        popularity: candidate.follows.count
      }
    end
  end

  # Sort by: distance (nearest first), then popularity (most followed first)
  same_cat_with_distance.sort_by! { |item| [item[:distance], -item[:popularity]] }

  # Take up to max_results from same category
  same_cat_with_distance.take(max_results).each do |item|
    final_results << item[:biz]
    result_ids << item[:biz].id
  end

  # =========================================================
  # STEP 2: Other-category approved businesses within radius
  # =========================================================
  # Only query if we need more results
  if final_results.size < max_results
    remaining_slots = max_results - final_results.size

    other_cat_candidates = Business
      .includes(:business_location, :business_hours, :business_contact,
                profile_picture_attachment: :blob)
      .where(status: "approved")
      .where.not(id: excluded_ids + result_ids.to_a)
      .where.not(user_id: current_user.id)
      .where.not(category: business.category)
      .joins(:business_location)

    other_cat_with_distance = []
    other_cat_candidates.each do |candidate|
      candidate_loc = candidate.business_location
      # Skip if candidate has missing/invalid coordinates
      next unless candidate_loc&.latitude && candidate_loc&.longitude

      # Calculate distance from the viewed business to candidate
      distance = calc_distance.call(
        business_loc.latitude, business_loc.longitude,
        candidate_loc.latitude, candidate_loc.longitude
      )

      # Include if within other-category radius
      if distance && distance <= other_category_radius
        other_cat_with_distance << {
          biz: candidate,
          distance: distance,
          popularity: candidate.follows.count
        }
      end
    end

    # Sort by: distance (nearest first), then popularity (most followed first)
    other_cat_with_distance.sort_by! { |item| [item[:distance], -item[:popularity]] }

    # Take only what we need to reach max_results
    other_cat_with_distance.take(remaining_slots).each do |item|
      final_results << item[:biz]
      result_ids << item[:biz].id
    end
  end

  # =========================================================
  # RESPONSE
  # =========================================================
  render json: final_results,
         each_serializer: BusinessSerializer,
         scope: current_user,
         user_lat: reference_lat,
         user_lng: reference_lng
end



  # =========================================================
  # 🔵 BUSINESS DETAIL PAGE
  # GET /api/v1/businesses/:id
  # =========================================================
  def show
    current_user.live_locations.load

    business = Business.includes(
                  :business_location,
                  :business_contact,
                  :business_hours,
                  :follows, :likes, :global_feeds,
                  { user: [:jobs, :offers] },
                  shop_images_attachments: :blob,
                  profile_picture_attachment: :blob
                ).find(params[:id])

    # Forward client GPS coords to the serializer so distance reflects the
    # user's actual current position rather than their last saved DB location.
    opts = {}
    if params[:lat].present? && params[:lng].present?
      opts[:user_lat] = params[:lat].to_f
      opts[:user_lng] = params[:lng].to_f
    end

    render json: business,
           serializer: BusinessSerializer,
           scope: current_user,
           **opts
  end
  

  # =========================================================
  # 🔄 TOGGLE ONLINE STATUS
  # PATCH /businesses/online_status
  # =========================================================
  def toggle_online
    business = current_user.business
    return render json: { error: "Business not found" }, status: :not_found unless business

    business.update!(is_online: !business.is_online)
    render json: { is_online: business.is_online }, status: :ok
  end

  # =========================================================
  # 🗑️ DELETE GALLERY IMAGE
  # DELETE /businesses/images/:blob_id
  # =========================================================
  def delete_image
    business = current_user.business
    return render json: { error: "Business not found" }, status: :not_found unless business

    attachment = business.shop_images_attachments.find_by(blob_id: params[:blob_id])
    return render json: { error: "Image not found" }, status: :not_found unless attachment

    attachment.purge
    render json: { message: "Image deleted" }, status: :ok
  end

  private

  # =========================================================
  # 📍 USER LOCATION
  # =========================================================
  def set_user_location
    @user_location = current_user.live_locations.find_by(live_location_default: true)
  end

  def business_params
    params.require(:business).permit(
      :name, :category, :about, :year_established, :website,
      keywords:         [],
      video_links:      [],
      products_services: []
    )
  end
end

