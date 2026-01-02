class GlobalFeedsController < ApplicationController
  before_action :authorize_request
  before_action :set_global_feed, only: [:show, :update, :destroy]

  # GET /global_feeds
  def index
    feeds = GlobalFeed.order(created_at: :desc)
    render json: feeds.map { |feed| feed_response(feed) }
  end

  # GET /global_feeds/:id
  def show
    render json: feed_response(@global_feed)
  end

  # POST /global_feeds
  def create
    feed = GlobalFeed.new(feed_params)

    normalize_tags(feed)
    normalize_links(feed)
    attach_media(feed)

    if feed.save
      render json: feed_response(feed), status: :created
    else
      render json: { errors: feed.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /global_feeds/:id
  def update
    @global_feed.assign_attributes(feed_params)

    normalize_tags(@global_feed)
    normalize_links(@global_feed)
    attach_media(@global_feed)

    if @global_feed.save
      render json: feed_response(@global_feed)
    else
      render json: { errors: @global_feed.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /global_feeds/:id
  def destroy
    @global_feed.destroy
    render json: { message: "Global feed deleted successfully" }
  end

  private

  def set_global_feed
    @global_feed = GlobalFeed.find(params[:id])
  end

  def feed_params
    params.permit(
      :title,
      :description,
      :category,
      :disappear_after
    )
  end

  # -------- NORMALIZERS --------

  def normalize_tags(feed)
    feed.tags = params[:tags] if params[:tags].present?
  end

  def normalize_links(feed)
    return unless params[:links].present?

    # Convert {"0"=>{...}} → [{...}]
    feed.links = params[:links].values
  end

  def attach_media(feed)
    return unless params[:media].present?

    feed.media.attach(params[:media])
  end

  # -------- RESPONSE --------

  def feed_response(feed)
    {
      id: feed.id,
      title: feed.title,
      description: feed.description,
      category: feed.category,
      tags: feed.tags || [],
      links: feed.links || [],
      disappear_after: feed.disappear_after,
      media: feed.media.map do |file|
        {
          id: file.id,
          url: url_for(file),
          content_type: file.content_type
        }
      end,
      created_at: feed.created_at
    }
  end
end
