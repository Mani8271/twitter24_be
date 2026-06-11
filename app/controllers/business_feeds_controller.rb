class BusinessFeedsController < ApplicationController
  before_action :authorize_request

  def index
    business = Business.find(params[:business_id])

    case params[:type]
    when "local", "global"
      feeds = business.global_feeds
                      .active
                      .where(feed_type: params[:type])
                      .order(created_at: :desc)

      render json: feeds,
             each_serializer: GlobalFeedSerializer,
             scope: current_user

    when "jobs"
      jobs = business.jobs.active.order(created_at: :desc)
      render json: jobs,
             each_serializer: JobSerializer,
             scope: current_user

    when "offers"
      offers = business.offers.active.order(created_at: :desc)
      render json: offers,
             each_serializer: OfferSerializer,
             scope: current_user

    else
      render json: { error: "Invalid type" }, status: :bad_request
    end
  end
end
