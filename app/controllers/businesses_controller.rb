
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

  render json: businesses,
         each_serializer: BusinessSerializer,
         scope: current_user
end

def update
  business = current_user.business

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
  business = Business.includes(:business_location).find(params[:id])
  loc      = business.business_location
  user_loc = @user_location

  # Collect same-category businesses (excluding the current one)
  same_cat = Business
               .includes(:business_location, :business_hours, :business_contact,
                         profile_picture_attachment: :blob)
               .where(status: "approved")
               .where(category: business.category)
               .where.not(id: business.id)
               .limit(6)

  results = same_cat.to_a

  # If fewer than 3, fill with nearby businesses from other categories
  if results.size < 3
    other = Business
              .includes(:business_location, :business_hours, :business_contact,
                        profile_picture_attachment: :blob)
              .where(status: "approved")
              .where.not(id: [business.id] + results.map(&:id))
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
    business = Business.includes(
                  :business_location,
                  :business_contact,
                  :business_hours,
                  shop_images_attachments: :blob,
                  profile_picture_attachment: :blob
                ).find(params[:id])

    render json: business,
           serializer: BusinessSerializer,
           scope: current_user
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

