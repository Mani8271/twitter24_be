
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
                end            
  # ✅ Filter for favorites if query param is present
  if params[:favourites].to_s.downcase == "true"
    businesses = businesses.joins(:likes)
                           .where(likes: { user_id: current_user.id })
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
  

  private

  # =========================================================
  # 📍 USER LOCATION
  # =========================================================
  def set_user_location
    @user_location = current_user.live_locations.find_by(live_location_default: true)
  end
end

