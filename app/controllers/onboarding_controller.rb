class OnboardingController < ApplicationController
  include PlanAuthorized

  # Helpers
  def business
    @business ||= current_user.business || current_user.create_business!(status: "draft", products_services: [])
    # Invariant: @business always belongs to current_user because it is fetched/created
    # through the current_user association. Raise loudly if this assumption is ever violated.
    raise "Ownership invariant violated" unless @business.user_id == current_user.id
    @business
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
      render json: { message: "Successfully saved details", progress: progress }, status: :ok
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
      render json: { message: "Successfully saved details", progress: progress }, status: :ok
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
      render json: { message: "Successfully saved details", progress: progress }, status: :ok
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
    render json: { message: "Successfully saved details", progress: progress }, status: :ok
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
      render json: { message: "Successfully saved details", progress: progress }, status: :ok
    else
      render json: { errors: doc.errors.full_messages }, status: :unprocessable_entity
    end
  end

  ALLOWED_IMAGE_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  IMAGE_MAX_BYTES     = 10.megabytes

  # ===================== STEP 6 =====================
  # Images (ActiveStorage)
  # POST /onboarding/step6 (multipart/form-data)
  # profile_picture: file
  # shop_images[]: files
  def step6_images
    # profile picture optional — validate before attaching
    if params[:profile_picture].present?
      begin
        validate_upload!(params[:profile_picture])
      rescue ArgumentError => e
        return render json: { error: e.message }, status: :unprocessable_entity
      end
      business.profile_picture.attach(params[:profile_picture])
    end

    # gallery images — validate each file
    if params[:shop_images].present?
      Array.wrap(params[:shop_images]).each do |img|
        begin
          validate_upload!(img)
        rescue ArgumentError => e
          return render json: { error: e.message }, status: :unprocessable_entity
        end
      end
    end

    # Subscription plan limits apply only when managing an already-completed domain (My Domain page).
    # During initial onboarding the user has no subscription yet, so checks are skipped.
    if params[:shop_images].present?
      if progress.completed
        return unless require_feature!("domain_uploads")

        limit = current_user.feature_limit("domain_uploads")
        if limit
          new_count     = Array.wrap(params[:shop_images]).length
          current_count = business.shop_images.count
          if current_count + new_count > limit
            return render json: {
              error:            "Uploading #{new_count} image(s) would exceed your plan limit of #{limit}. " \
                                "You currently have #{current_count} image(s).",
              feature_key:      "domain_uploads",
              limit_reached:    true,
              limit:            limit,
              current_count:    current_count,
              upgrade_required: true
            }, status: :forbidden
          end
        end
      end

      business.shop_images.attach(params[:shop_images])
    end

    if business.shop_images.count < 3
      return render json: { error: "Please upload at least 3 shop images." }, status: :bad_request
    end

    mark_step_done(6)

    if progress.completed
      business.update!(status: "submitted", rejection_reason: nil)
      OnboardingMailer.admin_review_notification(current_user, business).deliver_now
    end

    render json: { message: "Successfully saved details", progress: progress }, status: :ok
  end

  # ===================== CONTACT OTP =====================
  # POST /onboarding/send_contact_otp
  def send_contact_otp
    phone_number = params[:phone_number]
    return render(json: { error: "phone_number is required" }, status: :bad_request) if phone_number.blank?

    otp = loop do
      candidate = rand(100000..999999).to_s
      break candidate unless OtpCode.exists?(otp_number: candidate)
    end

    OtpCode.create!(
      user_id:    current_user.id.to_s,
      phone_number: phone_number,
      otp_number: otp,
      otp_expiry: 5.minutes.from_now
    )

    Rails.logger.info "[ContactOTP] #{phone_number}: #{otp}"
    render json: { message: "OTP sent to #{phone_number}" }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "Could not generate OTP. Please try again." }, status: :unprocessable_entity
  end

  # POST /onboarding/verify_contact_otp
  def verify_contact_otp
    phone_number = params[:phone_number]
    otp_input    = params[:otp]
    return render(json: { error: "phone_number and otp are required" }, status: :bad_request) if phone_number.blank? || otp_input.blank?

    otp_record = OtpCode.where(user_id: current_user.id.to_s, phone_number: phone_number)
                        .order(created_at: :desc)
                        .first

    return render(json: { error: "Invalid OTP. Please try again." }, status: :unprocessable_entity) unless otp_record&.otp_number == otp_input
    return render(json: { error: "OTP expired. Please request a new one." }, status: :unprocessable_entity) if otp_record.otp_expiry < Time.current

    otp_record.destroy
    render json: { message: "Phone number verified successfully" }, status: :ok
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
        profile_picture: business.profile_picture.attached? ? attachment_url(business.profile_picture) : nil,
        shop_images: business.shop_images.map { |img| attachment_url(img) }
      }
    ),
    steps_completed: progress.steps_completed,
    current_step: progress.current_step,
    completed: progress.completed
  }, status: :ok
end


   def get_step1
    render json: current_user.business&.slice(
      :name, :category, :year_established, :website, :about, :products_services
    )
  end

  # GET /onboarding/step2
  def get_step2
    render json: current_user.business&.business_contact
  end

  # GET /onboarding/step3
  def get_step3
    render json: current_user.business&.business_location
  end

  # GET /onboarding/step4
  def get_step4
    render json: current_user.business&.business_hours
  end

  # GET /onboarding/step5
  def get_step5
    render json: current_user.business&.business_document
  end

  # GET /onboarding/step6
  def get_step6
    business = current_user.business

    render json: {
      profile_picture: business&.profile_picture&.attached? ? attachment_url(business.profile_picture) : nil,
      shop_images: business&.shop_images&.map { |img| attachment_url(img) } || []
    }
  end


  

  private

  # Uses the request host so the URL matches the origin that clients connect to.
  # Avoids blob.url which generates expiring S3 presigned URLs.
  def attachment_url(attachment)
    return nil unless attachment&.attached?
    blob = attachment.blob
    "#{request.base_url}/rails/active_storage/blobs/redirect/#{blob.signed_id}/#{blob.filename}"
  rescue StandardError
    nil
  end

   def validate_upload!(file)
    return if file.blank?
    unless ALLOWED_IMAGE_TYPES.include?(file.content_type)
      raise ArgumentError, "#{file.original_filename}: only JPEG, PNG, WebP, or GIF images are allowed."
    end
    if file.size > IMAGE_MAX_BYTES
      raise ArgumentError, "#{file.original_filename}: file must be 10 MB or smaller."
    end
  end

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
      :owner_email,
      :address_line1,
      :address_line2,
      :city,
      :state,
      :pincode
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
