class JobsController < ApplicationController
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
    jobs = Job.all

    jobs = jobs.where(user_id: current_user.id) if params[:my] == "true"
    jobs = jobs.where(post_type: params[:post_type]) if params[:post_type].present?
    jobs = jobs.by_search(params[:search])

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

    render json: jobs, each_serializer: JobSerializer, scope: current_user
  end

  # GET /jobs/:id
  def show
    render json: @job, serializer: JobSerializer, scope: current_user
  end

  # POST /jobs
  def create
    job = current_user.jobs.build(job_params)

    if job.save
      render json: job, serializer: JobSerializer, scope: current_user, status: :created
    else
      render json: { errors: job.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /jobs/:id
  def update
    return unauthorized unless @job.user_id == current_user.id

    if @job.update(job_params)
      render json: @job, serializer: JobSerializer, scope: current_user
    else
      render json: { errors: @job.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /jobs/:id
  def destroy
    return unauthorized unless @job.user_id == current_user.id

    @job.destroy
    render json: { message: "Job deleted successfully" }
  end

  private

  def set_job
    @job = Job.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Job not found" }, status: :not_found
  end

  def job_params
    params.permit(
      :location_name,
      :latitude,
      :longitude,
      :reach_distance,
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
      :image,
      links: [:button_name, :url]
    )
  end

  def unauthorized
    render json: { error: "Unauthorized" }, status: :forbidden
  end
end
