
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
    businesses = businesses.order(
      Arel.sql("(SELECT COUNT(*) FROM follows WHERE follows.followable_type = 'Business' AND follows.followable_id = businesses.id) DESC")
    )
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
# 🔗 RELATED BUSINESSES
# GET /businesses/:id/related
# =========================================================
def related
  current_user.live_locations.load

  business = Business.includes(:business_location).find(params[:id])

  # Collect same-category businesses (excluding the viewed business and current user's own)
  excluded_ids = [business.id]

  same_cat = Business
               .includes(:business_location, :business_hours, :business_contact,
                         profile_picture_attachment: :blob)
               .where(status: "approved")
               .where(category: business.category)
               .where.not(id: excluded_ids)
               .where.not(user_id: current_user.id)
               .limit(6)

  results = same_cat.to_a

  # If fewer than 3, fill with businesses from other categories
  if results.size < 3
    other = Business
              .includes(:business_location, :business_hours, :business_contact,
                        profile_picture_attachment: :blob)
              .where(status: "approved")
              .where.not(id: excluded_ids + results.map(&:id))
              .where.not(user_id: current_user.id)
              .where.not(category: business.category)
              .limit(6 - results.size)
    results += other.to_a
  end

  render json: results,
         each_serializer: BusinessSerializer,
         scope: current_user
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

