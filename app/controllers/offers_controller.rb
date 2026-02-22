class OffersController < ApplicationController
    before_action :authorize_request
    before_action :set_offer, only: [:show, :update, :destroy]
  
    # GET /api/v1/offers
    # ?offer_type=local
    # ?offer_type=global
    # ?my=true
    def index
      offers = Offer.active.order(created_at: :desc)
  
      # Filter by type
      offers = offers.by_type(params[:offer_type])
  
      # Show only current user's offers if my=true
      if params[:my].present? && params[:my] == "true"
        offers = offers.where(user_id: current_user.id)
      end
  
      render json: offers
    end
  
    # GET /api/v1/offers/:id
    def show
      render json: @offer
    end
  
    # POST /api/v1/offers
    def create
      offer = current_user.offers.build(offer_params)
  
      if offer.save
        render json: offer, status: :created
      else
        render json: { errors: offer.errors.full_messages }, status: :unprocessable_entity
      end
    end
  
    # PUT /api/v1/offers/:id
    def update
      return unauthorized unless @offer.user_id == current_user.id
  
      if @offer.update(offer_params)
        render json: @offer
      else
        render json: { errors: @offer.errors.full_messages }, status: :unprocessable_entity
      end
    end
  
    # DELETE /api/v1/offers/:id
    def destroy
      return unauthorized unless @offer.user_id == current_user.id
  
      @offer.destroy
      render json: { message: "Offer deleted successfully" }
    end
  
    private
  
    def set_offer
      @offer = Offer.find(params[:id])
    end
  
    def offer_params
      params.permit(
        :title,
        :description,
        :offer_type,
        :latitude,
        :longitude,
        :address,
        :reach_distance,
        :valid_till,
        :tags,
        :disappearing_days,
        :media,
        links: [:button_name, :url]
      )
    end
  
    def unauthorized
      render json: { error: "Unauthorized" }, status: :forbidden
    end
  end