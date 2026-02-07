class ReviewsController < ApplicationController
    before_action :authorize_request
    before_action :set_business
  
    # =====================================================
    # GET /api/v1/businesses/:business_id/reviews
    # =====================================================
    def index
      reviews = @business.reviews.includes(:user).order(created_at: :desc)
  
      render json: {
        average_rating: @business.average_rating || 0,
        reviews_count: @business.reviews_count || 0,
        reviews: reviews.map { |r| review_json(r) }
      }
    end
  
    # =====================================================
    # POST /api/v1/businesses/:business_id/reviews
    # One review per user per business (update if exists)
    # =====================================================
    def create
      review = @business.reviews.find_or_initialize_by(user: current_user)
      review.update!(rating: params[:rating], comment: params[:comment])
  
      render json: { message: "Review submitted successfully" }, status: :ok
    end
  
    private
  
    def set_business
      @business = Business.find(params[:business_id])
    end
  
    def review_json(r)
      {
        id: r.id,
        user_name: r.user.account_type == "business" ? r.user.business&.name : r.user.name,
        rating: r.rating,
        comment: r.comment,
        created_at: r.created_at.strftime("%d %b %Y")
      }
    end
  end
  