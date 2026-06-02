class OffersController < ApplicationController
    include PlanAuthorized
    include BusinessAuthorized

    before_action :authorize_request
    before_action :set_offer, only: [:show, :update, :destroy]
  
    # GET /api/v1/offers
    # ?offer_type=local
    # ?offer_type=global
    # ?my=true
    def index
      per_page = 10
      page     = [params[:page].to_i, 1].max

      offers = Offer.from_active_users.active.order(created_at: :desc)

      offers = offers.by_type(params[:offer_type])

      if params[:my].present? && params[:my] == "true"
        offers = offers.where(user_id: current_user.id)
      end
      offers = offers.where(user_id: params[:user_id]) if params[:user_id].present?

      if params[:q].present?
        like = "%#{params[:q].downcase}%"
        offers = offers.where(
          "LOWER(title) LIKE :q OR LOWER(description) LIKE :q OR LOWER(tags) LIKE :q",
          q: like
        )
      end

      # Filter by business category
      if params[:categories].present?
        cats = params[:categories].split(",").map(&:strip).reject(&:blank?)
        offers = offers.joins(user: :business).where(businesses: { category: cats }) if cats.any?
      end

      total  = offers.count
      offers = offers.offset((page - 1) * per_page).limit(per_page)

      render json: {
        offers: ActiveModelSerializers::SerializableResource.new(offers, each_serializer: OfferSerializer, scope: current_user).as_json,
        meta: {
          page:       page,
          per_page:   per_page,
          total:      total,
          has_more:   (page * per_page) < total,
          request_id: params[:request_id].presence
        }
      }
    end
  
    # GET /api/v1/offers/:id
    def show
      render json: @offer, serializer: OfferSerializer, scope: current_user
    end
  
    # POST /api/v1/offers
    def create
      return unless require_business!
      return unless require_feature!("offers")
      return unless check_limit!("offers")

      offer = current_user.offers.build(offer_params)
      offer.reach_distance = current_user.effective_range("offers") || 10
      normalize_links(offer)
      if offer.disappearing_days.present? && offer.valid_till.blank?
        offer.valid_till = Time.current + offer.disappearing_days.days
      end

      if offer.save
        current_user.increment_subscription_usage!("offers")
        render json: offer, serializer: OfferSerializer, scope: current_user, status: :created
      else
        render json: { errors: offer.errors.full_messages }, status: :unprocessable_entity
      end
    end
  
    # PUT /api/v1/offers/:id
    def update
      return unless require_business!
      return unauthorized unless @offer.user_id == current_user.id

      @offer.assign_attributes(offer_params.except(:title))
      normalize_links(@offer)
      if @offer.save
        render json: @offer, serializer: OfferSerializer, scope: current_user
      else
        render json: { errors: @offer.errors.full_messages }, status: :unprocessable_entity
      end
    end
  
    # DELETE /api/v1/offers/:id
    def destroy
      return unless require_business!
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
        :valid_from,
        :valid_till,
        :tags,
        :disappearing_days,
        media: [],
        links: [:name, :url]
      )
    end

    def normalize_links(offer)
      return unless params[:links].present?

      raw = params[:links]
      links_array =
        if raw.is_a?(String)
          begin
            parsed = JSON.parse(raw)
            parsed.is_a?(Array) ? parsed : [parsed]
          rescue JSON::ParserError
            []
          end
        elsif raw.is_a?(Array)
          raw
        elsif raw.is_a?(ActionController::Parameters)
          h = raw.to_unsafe_h
          h.keys.all? { |k| k.to_s =~ /^\d+$/ } ? h.values : [h]
        elsif raw.is_a?(Hash)
          raw.keys.all? { |k| k.to_s =~ /^\d+$/ } ? raw.values : [raw]
        else
          []
        end

      offer.links = links_array.map do |l|
        l.is_a?(ActionController::Parameters) ? l.to_unsafe_h : l
      end
    end
  
    def unauthorized
      render json: { error: "Unauthorized" }, status: :forbidden
    end
  end