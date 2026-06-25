class JobsController < ApplicationController
  include PlanAuthorized
  include BusinessAuthorized

  before_action :authorize_request
  before_action :set_job, only: [:show, :update, :destroy]

  # GET /jobs
  # ?my=true              → current user's jobs only
  # ?post_type=local|global
  # ?search=              → job_title / description / skills / location
  # ?job_type=            → full_time, part_time, contract, internship, freelance (comma-separated)
  # ?experience=          → Fresher, 1 year... (comma-separated)
  # ?salary_min=          → minimum salary
  # ?salary_max=          → maximum salary
  # ?sort=newest|oldest|salary_asc|salary_desc
  def index
    per_page = 20
    page     = [params[:page].to_i, 1].max

    jobs = Job.from_active_users

    jobs = jobs.where(user_id: current_user.id) if params[:my] == "true"
    jobs = jobs.where(user_id: params[:user_id]) if params[:user_id].present?
    jobs = jobs.where(post_type: params[:post_type]) if params[:post_type].present?
    jobs = jobs.by_search(params[:search])

    # Filter by business category
    if params[:categories].present?
      cats = params[:categories].split(",").map(&:strip).reject(&:blank?)
      jobs = jobs.joins(user: :business).where(businesses: { category: cats }) if cats.any?
    end

    if params[:job_type].present?
      types = params[:job_type].split(",").map(&:strip)
      jobs = jobs.where(job_type: types)
    end

    if params[:experience].present?
      exps = params[:experience].split(",").map(&:strip)
      jobs = jobs.where(experience: exps)
    end

    jobs = jobs.by_salary_min(params[:salary_min])
    jobs = jobs.by_salary_max(params[:salary_max])
    jobs = jobs.sorted_by(params[:sort])

    total = jobs.count
    # FIXED: Add eager loading to prevent N+1 queries when serializing
    jobs  = jobs.includes(:user, :images)
               .offset((page - 1) * per_page)
               .limit(per_page)

    render json: {
      jobs: ActiveModelSerializers::SerializableResource.new(jobs, each_serializer: JobSerializer, scope: current_user).as_json,
      meta: {
        page:       page,
        per_page:   per_page,
        total:      total,
        has_more:   (page * per_page) < total,
        request_id: params[:request_id].presence
      }
    }
  end

  # GET /jobs/:id
  def show
    # FIXED: Eager load associations to prevent N+1 queries
    @job = @job.includes(:user, :images) if @job
    render json: @job, serializer: JobSerializer, scope: current_user
  end

  # POST /jobs
  def create
    return unless require_business!
    return unless require_feature!("job_posts")
    return unless check_limit!("job_posts")

    job = current_user.jobs.build(job_params)
    job.reach_distance = current_user.effective_range("job_posts") || 10
    normalize_links(job)

    if job.save
      current_user.increment_subscription_usage!("job_posts")
      render json: job, serializer: JobSerializer, scope: current_user, status: :created
    else
      render json: { errors: job.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /jobs/:id
  def update
    return unless require_business!
    return unauthorized unless @job.user_id == current_user.id

    @job.assign_attributes(job_params.except(:job_title))
    normalize_links(@job)
    if @job.save
      render json: @job, serializer: JobSerializer, scope: current_user
    else
      render json: { errors: @job.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /jobs/:id
  def destroy
    return unless require_business!
    return unauthorized unless @job.user_id == current_user.id

    @job.destroy
    render json: { message: "Job deleted successfully" }
  end

  private

  def set_job
    # FIXED: Eager load associations to prevent N+1 queries in show/update/destroy
    @job = Job.includes(:user, :images)
              .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Job not found" }, status: :not_found
  end

  def job_params
    params.permit(
      :location_name,
      :latitude,
      :longitude,
      :job_title,
      :salary,
      :experience,
      :job_type,
      :working_hours,
      :description,
      :skills_required,
      :post_type,
      :tags,
      :disappearing_days,
      images: [],
      links: [:name, :url]
    )
  end

  def normalize_links(job)
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

    job.links = links_array.map do |l|
      l.is_a?(ActionController::Parameters) ? l.to_unsafe_h : l
    end
  end

  def unauthorized
    render json: { error: "Unauthorized" }, status: :forbidden
  end
end
