class BusinessFeedsController < ApplicationController
  before_action :authorize_request

  def index
    business = Business.find(params[:business_id])

    case params[:type]
    when "local", "global"
      feeds = business.global_feeds
                      .where(feed_type: params[:type])
                      .order(created_at: :desc)

      render json: feeds,
             each_serializer: GlobalFeedSerializer,
             scope: current_user

    when "jobs"
      jobs = business.jobs.order(created_at: :desc)
      render json: jobs.map { |job| job_response(job) }

    when "offers"
      offers = business.offers.order(created_at: :desc)
      render json: offers.map { |offer| offer_response(offer) }

    else
      render json: { error: "Invalid type" }, status: :bad_request
    end
  end

  private

  # ===========================
  # TEMP RESPONSES (non-feed)
  # ===========================
  def job_response(job)
    {
      id: job.id,
      title: job.title,
      company: job.company_name,
      location: job.location,
      created_at: job.created_at
    }
  end

  def offer_response(offer)
    {
      id: offer.id,
      title: offer.title,
      discount: offer.discount,
      valid_till: offer.valid_till,
      created_at: offer.created_at
    }
  end
end
