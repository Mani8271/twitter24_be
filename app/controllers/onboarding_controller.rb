class OnboardingController < ApplicationController

  # Helpers
  def business
    @business ||= current_user.business || current_user.create_business!(status: "draft", products_services: [])
  end

  def progress
    # Ensure onboarding_progress is linked to the business as well
    @progress ||= current_user.onboarding_progress || create_onboarding_progress_for_business
  end

  def mark_step_done(step)
    steps = progress.steps_completed || []
    steps << step unless steps.include?(step)
    progress.update!(
      steps_completed: steps,
      current_step: [progress.current_step, step + 1].max,
      completed: steps.sort == [1,2,3,4,5,6]
    )
    progress.update!(completed_at: Time.current) if progress.completed && progress.completed_at.nil?
  end

  # ===================== STEP 1 =====================
  # Business Details
  # POST /onboarding/step1
  def step1_business_details

    if business.update(step1_params)
        
      mark_step_done(1)
      render json: { message: "Step 1 saved", progress: progress }, status: :ok
    else
      render json: { errors: business.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # ===================== STEP 2 =====================
  # Contact Info
  # POST /onboarding/step2
  def step2_contact_info
    contact = business.business_contact || business.build_business_contact

    if contact.update(step2_params)
      mark_step_done(2)
      render json: { message: "Step 2 saved", progress: progress }, status: :ok
    else
      render json: { errors: contact.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # ===================== STEP 3 =====================
  # Location
  # POST /onboarding/step3
  def step3_location
    location = business.business_location || business.build_business_location

    if location.update(step3_params)
      mark_step_done(3)
      render json: { message: "Step 3 saved", progress: progress }, status: :ok
    else
      render json: { errors: location.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # ===================== STEP 4 =====================
  # Business Hours (array of 7 days)
  # POST /onboarding/step4
  # body: { hours: [ {day_of_week:0,is_open:true,opens_at:"09:00",closes_at:"18:00"}, ... ] }
  def step4_hours
    hours = params[:hours]
    return render json: { error: "hours is required" }, status: :bad_request if hours.blank? || !hours.is_a?(Array)

    ActiveRecord::Base.transaction do
      hours.each do |h|
        day = h[:day_of_week] || h["day_of_week"]
        record = business.business_hours.find_or_initialize_by(day_of_week: day)
        record.update!(
          is_open: h[:is_open] || h["is_open"],
          opens_at: h[:opens_at] || h["opens_at"],
          closes_at: h[:closes_at] || h["closes_at"]
        )
      end
    end

    mark_step_done(4)
    render json: { message: "Step 4 saved", progress: progress }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # ===================== STEP 5 =====================
  # Documents
  # POST /onboarding/step5
  def step5_documents
    doc = business.business_document || business.build_business_document

    if doc.update(step5_params)
      mark_step_done(5)
      render json: { message: "Step 5 saved", progress: progress }, status: :ok
    else
      render json: { errors: doc.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # ===================== STEP 6 =====================
  # Images (ActiveStorage)
  # POST /onboarding/step6 (multipart/form-data)
  # profile_picture: file
  # shop_images[]: files
  def step6_images
    # profile picture optional
    if params[:profile_picture].present?
      business.profile_picture.attach(params[:profile_picture])
    end

    # gallery images optional
    if params[:shop_images].present?
      business.shop_images.attach(params[:shop_images])
    end

    # Validate at least 1 image if your UI requires
    if !business.profile_picture.attached? && business.shop_images.blank?
      return render json: { error: "Upload profile_picture or shop_images" }, status: :bad_request
    end

    mark_step_done(6)
    business.update!(status: "submitted") if progress.completed

    render json: { message: "Step 6 saved", progress: progress }, status: :ok
  end

  # ===================== STATUS =====================
  # GET /onboarding/status
 
  def status
  render json: {
    business: business.as_json(except: [:created_at, :updated_at]).merge(
      contact_info: business.business_contact.as_json(except: [:created_at, :updated_at]),
      location: business.business_location.as_json(except: [:created_at, :updated_at]),
      business_hours: business.business_hours.as_json(except: [:created_at, :updated_at]),
      documents: business.business_document.as_json(except: [:created_at, :updated_at]),
      images: {
        # Conditionally include profile_picture if attached
        profile_picture: business.profile_picture.attached? ? url_for(business.profile_picture) : nil,
        shop_images: business.shop_images.map { |img| url_for(img) }
      }
    ),
    steps_completed: progress.steps_completed,
    current_step: progress.current_step,
    completed: progress.completed
  }, status: :ok
end


  

  private
   def create_onboarding_progress_for_business
    OnboardingProgress.create!(
      user_id: current_user.id,
      business_id: business.id, # Linking the OnboardingProgress with the Business
      current_step: 1,
      steps_completed: []
    )
  end

  # def step1_params
  #   params.permit(:name, :category, :year_established, :website, :about, products_services: [])
  # end
  def step1_params
  # Permit individual fields rather than the 'onboarding' object
  params.permit(:name, :category, :year_established, :website, :about, products_services: [])
end

  def step2_params
    params.permit(
      :contact_person_name,
      :contact_phone,
      :contact_phone_verified,
      :contact_email,
      :owner_name,
      :owner_phone,
      :owner_phone_verified,
      :owner_email
    )
  end

  def step3_params
    params.permit(
      :map_address,
      :latitude,
      :longitude,
      :place_id,
      :address_line1,
      :address_line2,
      :city,
      :state,
      :pin_code
    )
  end

  def step5_params
    params.permit(
      :has_gstin, :gstin,
      :has_pan, :pan,
      :has_fssai, :fssai
    )
  end
end
