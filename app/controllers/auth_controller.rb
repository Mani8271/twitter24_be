class AuthController < ApplicationController
   skip_before_action :authorize_request

  # POST /signup
  def signup
    user = User.new(user_params)

    if user.save
      render json: {
        message: "User created successfully.",
        user: UserSerializer.new(user)
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_content
    end
  end

  MAX_OTP_RESENDS_PER_DAY = 5

  # POST /send_otp
  def send_otp
    phone_number = params[:phone_number]
    return render(json: { error: "phone_number is required" }, status: :bad_request) if phone_number.blank?

    user = User.find_by(phone_number: phone_number)
    return render(json: { error: "User not found. Please sign up first." }, status: :not_found) unless user

    # ── 60-second cooldown between consecutive resends ──────────────────────
    last_otp = OtpCode.where(user_id: user.id).order(created_at: :desc).first
    if last_otp && last_otp.created_at > 60.seconds.ago
      remaining = (60 - (Time.current - last_otp.created_at).to_i)
      return render json: { error: "Please wait #{remaining} seconds before requesting a new OTP." }, status: :too_many_requests
    end

    # ── 24-hour resend limit ─────────────────────────────────────────────────
    # Reset counter if the 24-hour window has passed
    if user.otp_resend_window_start.nil? || user.otp_resend_window_start < 24.hours.ago
      user.update_columns(otp_resend_count: 0, otp_resend_window_start: Time.current)
    end

    if user.otp_resend_count >= MAX_OTP_RESENDS_PER_DAY
      window_resets_at = user.otp_resend_window_start + 24.hours
      hours_left = ((window_resets_at - Time.current) / 3600).ceil
      return render json: {
        error: "You have reached the maximum of #{MAX_OTP_RESENDS_PER_DAY} OTP requests per day. Try again in #{hours_left} hour(s).",
        resend_limit_reached: true,
        resets_in_hours: hours_left
      }, status: :too_many_requests
    end

    otp = user.generate_otp
    user.increment!(:otp_resend_count)

    Rails.logger.info "OTP sent to #{user.phone_number}: #{otp} (resend #{user.otp_resend_count}/#{MAX_OTP_RESENDS_PER_DAY} today)"

    render json: {
      message: "OTP sent to #{user.phone_number}",
      otp: otp,
      resends_remaining: MAX_OTP_RESENDS_PER_DAY - user.otp_resend_count
    }, status: :ok
  end

  # POST /signin
  def signin
    phone_number = params[:phone_number]
    password = params[:password]

    if phone_number.blank? || password.blank?
      return render json: { error: "Phone Number and Password are required" }, status: :bad_request
    end

    user = User.find_by(phone_number: phone_number)

    unless user&.authenticate(password)
      return render json: { error: "Invalid Phone Number or Password" }, status: :unauthorized
    end

    if user.deleted?
      return render json: { error: "This account has been deleted." }, status: :forbidden
    end

    unless user.is_active
      return render json: { error: "account_inactive" }, status: :forbidden
    end

    token = JsonWebToken.encode({ user_id: user.id })
    exp = 1.year.from_now.strftime("%m-%d-%Y %H:%M")

    

    render json: {
      message: "Login successful",
      token: token,
      exp: exp,
      user: UserSerializer.new(user)
    }, status: :ok
  end

  # POST /verify_otp
  def verify_otp
    phone_number = params[:phone_number]
    otp_input = params[:otp]
    return render(json: { error: "phone_number and otp are required" }, status: :bad_request) if phone_number.blank? || otp_input.blank?

    user = User.find_by(phone_number: phone_number)
    return render(json: { error: "User not found" }, status: :not_found) unless user

    otp_record = OtpCode.find_by(user_id: user.id, otp_number: otp_input)

    if otp_record && otp_record.otp_number == otp_input
      if otp_record.otp_expiry < Time.current
        return render json: { error: "OTP expired" }, status: :unauthorized
      end
        user.update(phone_verified: true)
      token = JsonWebToken.encode({ user_id: user.id })
      exp_formatted = (Time.now + 365.days).strftime("%m-%d-%Y %H:%M")

      render json: {
        message: "OTP verified successfully",
        token: token,
        exp: exp_formatted,
        user: UserSerializer.new(user)
      }, status: :ok
    else
      render json: { error: "Invalid OTP" }, status: :unauthorized
    end
  end

  # POST /reset_password
  def reset_password
    phone_number = params[:phone_number]
    password = params[:password]
    password_confirmation = params[:password_confirmation]

    if phone_number.blank? || password.blank? || password_confirmation.blank?
      return render json: { error: "phone_number, password, password_confirmation are required" }, status: :bad_request
    end

    user = User.find_by(phone_number: phone_number)
    return render json: { error: "User not found" }, status: :not_found unless user

    unless password == password_confirmation
      return render json: { error: "Password and password confirmation do not match" }, status: :unprocessable_content
    end

    if user.update(password: password, password_confirmation: password_confirmation)
      render json: { message: "Password reset successful. Please login." }, status: :ok
    else
      render json: { error: user.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.permit(
      :name,
      :email,
      :phone_number,
      :password,
      :password_confirmation,
      :profile_picture,
      :current_location_id,
      :country_id,
      :region_id,
      :locale,
      :currency_pref,
      :zone_location_id,
        :account_type, 
      :email_verified,     
      :phone_verified 
    )
  end
end
