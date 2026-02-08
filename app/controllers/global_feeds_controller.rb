
# class GlobalFeedsController < ApplicationController
#   before_action :authorize_request
#   before_action :set_global_feed, only: [:show, :update, :destroy]

# def index
#   feeds = GlobalFeed.order(created_at: :desc)

#   # ✅ 1) TYPE filter (local/global)
#   if params[:type].present?
#     unless %w[global local].include?(params[:type])
#       return render json: { error: "Invalid type. Use type=global or type=local" }, status: :bad_request
#     end
#     feeds = feeds.where(feed_type: params[:type])
#   end

#   # ✅ 2) SCOPE filter
#   # default (discover) => exclude current_user posts
#   if params[:scope] == "my"
#     feeds = feeds.where(user_id: current_user.id)
#   else
#     feeds = feeds.where.not(user_id: current_user.id)
#   end

#   # ✅ 3) SEARCH filter
#   if params[:q].present?
#     q = params[:q].to_s.strip
#     if q.present?
#       like = "%#{q.downcase}%"
#       feeds = feeds.where(
#         "LOWER(title) LIKE :q OR LOWER(description) LIKE :q OR LOWER(category) LIKE :q OR LOWER(address) LIKE :q",
#         q: like
#       )
#     end
#   end
#   render json: feeds,
#          each_serializer: GlobalFeedSerializer,
#          scope: current_user
# end


#   # GET /global_feeds/:id
#  def show
#   render json: @global_feed,
#          serializer: GlobalFeedSerializer,
#          scope: current_user
# end


#   # POST /global_feeds
#   def create
#     feed = GlobalFeed.new(feed_params.except(:media))
#     feed.user_id = current_user.id

#     normalize_tags(feed)
#     normalize_links(feed)

#     if feed.save
#       # ✅ ATTACH MEDIA ONLY ONCE (AFTER SAVE)
#       if feed_params[:media].present?
#         feed.media.attach(feed_params[:media])
#       end

#       render json: feed,
#        serializer: GlobalFeedSerializer,
#        scope: current_user,
#        status: :created
#     else
#       render json: { errors: feed.errors.full_messages }, status: :unprocessable_entity
#     end
#   end

#   # PATCH /global_feeds/:id
#   def update
#     unless @global_feed.user_id == current_user.id
#       return render json: { error: "Not authorized" }, status: :forbidden
#     end

#     @global_feed.assign_attributes(feed_params.except(:media))

#     normalize_tags(@global_feed)
#     normalize_links(@global_feed)

#     if @global_feed.save
#       # ✅ replace media only if new media sent
#       if feed_params[:media].present?
#         @global_feed.media.purge
#         @global_feed.media.attach(feed_params[:media])
#       end

#       render json: feed_response(@global_feed)
#     else
#       render json: { errors: @global_feed.errors.full_messages }, status: :unprocessable_entity
#     end
#   end

#   # DELETE /global_feeds/:id
#   def destroy
#     unless @global_feed.user_id == current_user.id
#       return render json: { error: "Not authorized" }, status: :forbidden
#     end

#     @global_feed.destroy
#     render json: { message: "Feed deleted successfully" }
#   end

#   private

#   def set_global_feed
#     @global_feed = GlobalFeed.find(params[:id])
#   end

#   # ✅ STRONG PARAMS (FINAL)
#   def feed_params
#     params.permit(
#       :title,
#       :description,
#       :category,
#       :disappear_after,
#       :feed_type,

#       # local fields
#       :latitude,
#       :longitude,
#       :address,
#       :reach_distance,

#       # arrays
#       tags: [],
#       media: [],

#       # links array
#       links: [:name, :url]
#     )
#   end

#   # -------- NORMALIZERS --------

#   def normalize_tags(feed)
#     feed.tags = feed_params[:tags] if feed_params[:tags].present?
#   end

#   def normalize_links(feed)
#     return unless params[:links].present?

#     raw = params[:links]

#     links_array =
#       if raw.is_a?(ActionController::Parameters)
#         h = raw.to_unsafe_h
#         h.keys.all? { |k| k.to_s =~ /^\d+$/ } ? h.values : [h]
#       elsif raw.is_a?(Hash)
#         raw.keys.all? { |k| k.to_s =~ /^\d+$/ } ? raw.values : [raw]
#       elsif raw.is_a?(Array)
#         raw
#       elsif raw.is_a?(String)
#         begin
#           parsed = JSON.parse(raw)
#           parsed.is_a?(Array) ? parsed : [parsed]
#         rescue JSON::ParserError
#           []
#         end
#       else
#         []
#       end

#     feed.links = links_array.map do |l|
#       l.is_a?(ActionController::Parameters) ? l.to_unsafe_h : l
#     end
#   end

#   # -------- RESPONSE --------

#   def feed_response(feed)
#     {
#       id: feed.id,
#       user_id: feed.user_id,
#       feed_type: feed.feed_type,

#       title: feed.title,
#       description: feed.description,
#       category: feed.category,

#       tags: feed.tags || [],
#       links: feed.links || [],
#       disappear_after: feed.disappear_after,

#       latitude: feed.latitude,
#       longitude: feed.longitude,
#       address: feed.address,
#       reach_distance: feed.reach_distance,
#       likes_count: feed.likes.count,
#       comments_count: feed.comments.count,
#       views_count: feed.views.count,
#       liked_by_me: feed.likes.exists?(user_id: current_user.id),
#          posted_by: user.account_type, # "user" or "business"

#     business: business ? {
#       id: business.id,
#       name: business.name,
#       category: business.category,
#       profile_picture: business.profile_picture.attached? ? url_for(business.profile_picture) : nil
#     } : nil,


#       media: feed.media.map do |file|
#         {
#           id: file.id,
#           url: url_for(file),
#           content_type: file.content_type
#         }
#       end,

#       created_at: feed.created_at

#     }
#   end
# end

class GlobalFeedsController < ApplicationController
  before_action :authorize_request
  before_action :set_global_feed, only: [:show, :update, :destroy]

  def index
    feeds = GlobalFeed.order(created_at: :desc)

    if params[:type].present?
      unless %w[global local].include?(params[:type])
        return render json: { error: "Invalid type" }, status: :bad_request
      end
      feeds = feeds.where(feed_type: params[:type])
    end

    if params[:scope] == "my"
      feeds = feeds.where(user_id: current_user.id)
    else
      feeds = feeds.where.not(user_id: current_user.id)
    end

    if params[:q].present?
      like = "%#{params[:q].downcase}%"
      feeds = feeds.where(
        "LOWER(title) LIKE :q OR LOWER(description) LIKE :q OR LOWER(category) LIKE :q OR LOWER(address) LIKE :q",
        q: like
      )
    end

    render json: feeds,
           each_serializer: GlobalFeedSerializer,
           scope: current_user
  end

  def show
    render json: @global_feed,
           serializer: GlobalFeedSerializer,
           scope: current_user
  end

  def create
    feed = GlobalFeed.new(feed_params.except(:media))
    feed.user = current_user

    normalize_tags(feed)
    normalize_links(feed)

    if feed.save
      feed.media.attach(feed_params[:media]) if feed_params[:media].present?

      render json: feed,
             serializer: GlobalFeedSerializer,
             scope: current_user,
             status: :created
    else
      render json: { errors: feed.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    return render json: { error: "Not authorized" }, status: :forbidden if @global_feed.user != current_user

    @global_feed.assign_attributes(feed_params.except(:media))
    normalize_tags(@global_feed)
    normalize_links(@global_feed)

    if @global_feed.save
      if feed_params[:media].present?
        @global_feed.media.purge
        @global_feed.media.attach(feed_params[:media])
      end

      render json: @global_feed,
             serializer: GlobalFeedSerializer,
             scope: current_user
    else
      render json: { errors: @global_feed.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    return render json: { error: "Not authorized" }, status: :forbidden if @global_feed.user != current_user

    @global_feed.destroy
    render json: { message: "Feed deleted successfully" }
  end

  private

  def set_global_feed
    @global_feed = GlobalFeed.find(params[:id])
  end

  def feed_params
    params.permit(
      :title, :description, :category, :disappear_after, :feed_type,
      :latitude, :longitude, :address, :reach_distance,
      tags: [], media: [], links: [:name, :url]
    )
  end
end


