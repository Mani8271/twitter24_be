class OffersController < ApplicationController
    include PlanAuthorized

    before_action :authorize_request
    before_action :set_offer, only: [:show, :update, :destroy]
  
    # GET /api/v1/offers
    # ?offer_type=local
    # ?offer_type=global
    # ?my=true
    def index
      per_page = 10
      page     = [params[:page].to_i, 1].max

      offers = Offer.active.order(created_at: :desc)

      offers = offers.by_type(params[:offer_type])

      if params[:my].present? && params[:my] == "true"
        offers = offers.where(user_id: current_user.id)
      end
      offers = offers.where(user_id: params[:user_id]) if params[:user_id].present?

      total  = offers.count
      offers = offers.offset((page - 1) * per_page).limit(per_page)

      render json: {
        offers:  offers,
        meta: {
          page:     page,
          per_page: per_page,
          total:    total,
          has_more: (page * per_page) < total
        }
      }
    end
  
    # GET /api/v1/offers/:id
    def show
      render json: @offer
    end
  
    # POST /api/v1/offers
    def create
      return unless require_feature!("offers")
      return unless check_limit!("offers", current_user.offers.count)

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
      permitted = params.permit(
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
        media: [],
        links: [:button_name, :url]
      )
      permitted[:links] = permitted[:links].map(&:to_h) if permitted[:links].present?
      permitted
    end
  
    def unauthorized
      render json: { error: "Unauthorized" }, status: :forbidden
    end
  end