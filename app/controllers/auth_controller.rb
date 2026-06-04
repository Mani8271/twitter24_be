class AuthController < ApplicationController
  # reset_password is intentionally excluded — it requires the JWT issued by
  # verify_otp so the server can confirm the caller owns the account being changed.
  skip_before_action :authorize_request, only: [:signup, :signin, :send_otp, :verify_otp]

  # POST /signup
  def signup
    user = User.new(user_params)
    # Set is_new_business_user to true for new business accounts
    user.is_new_business_user = true if user.account_type == "business"

    if user.save
      render json: {
        message: "User created successfully.",
        user: UserSerializer.new(user)
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_content
    end
  end

  # 1 initial send + 3 resends = 4 total sends allowed per 24-hour window.
  MAX_OTP_RESENDS_PER_DAY = 4

  # POST /send_otp
  def send_otp
    phone_number = params[:phone_number]
    return render(json: { error: "phone_number is required" }, status: :bad_request) if phone_number.blank?

    unless phone_number.match?(/\A[6-9]\d{9}\z/)
      return render json: { error: "Mobile number must be exactly 10 digits and start with 6, 7, 8, or 9." }, status: :unprocessable_entity
    end

    # Acquire a row-level lock inside a transaction so that concurrent requests
    # for the same phone number are serialised — prevents the race where two
    # simultaneous requests both pass the count check before either increments.
    outcome = {}

    User.transaction do
      user = User.lock.find_by(phone_number: phone_number)

      unless user
        outcome = { error: :not_found }
        next
      end

      # ── 60-second cooldown between consecutive sends ───────────────────────
      last_otp = OtpCode.where(user_id: user.id).order(created_at: :desc).first
      if last_otp && last_otp.created_at > 60.seconds.ago
        remaining = (60 - (Time.current - last_otp.created_at).to_i)
        outcome = { error: :cooldown, remaining: remaining }
        next
      end

      # ── Reset 24-hour window if it has expired ────────────────────────────
      if user.otp_resend_window_start.nil? || user.otp_resend_window_start < 24.hours.ago
        user.update_columns(otp_resend_count: 0, otp_resend_window_start: Time.current)
      end

      # ── Daily limit ────────────────────────────────────────────────────────
      if user.otp_resend_count >= MAX_OTP_RESENDS_PER_DAY
        window_resets_at = user.otp_resend_window_start + 24.hours
        hours_left = ((window_resets_at - Time.current) / 3600).ceil
        outcome = { error: :rate_limited, hours_left: hours_left }
        next
      end

      otp = user.generate_otp
      user.increment!(:otp_resend_count)

      outcome = {
        ok: true,
        phone: user.phone_number,
        otp: otp,
        resends_remaining: MAX_OTP_RESENDS_PER_DAY - user.otp_resend_count
      }
    end

    case outcome[:error]
    when :not_found
      render json: { error: "User not found. Please sign up first." }, status: :not_found
    when :cooldown
      render json: { error: "Please wait #{outcome[:remaining]} seconds before requesting a new OTP." }, status: :too_many_requests
    when :rate_limited
      render json: {
        error: "You have reached the maximum resend limit. Please try again after 24 hours.",
        resend_limit_reached: true,
        resets_in_hours: outcome[:hours_left]
      }, status: :too_many_requests
    else
      Rails.logger.info "OTP sent to #{outcome[:phone]}: #{outcome[:otp]} (send #{MAX_OTP_RESENDS_PER_DAY - outcome[:resends_remaining]}/#{MAX_OTP_RESENDS_PER_DAY} today)"
      render json: {
        message: "OTP sent to #{outcome[:phone]}",
        otp: outcome[:otp],
        resends_remaining: outcome[:resends_remaining]
      }, status: :ok
    end
  end

  # POST /signin
  def signin
    phone_number = params[:phone_number]
    password = params[:password]

    if phone_number.blank? || password.blank?
      return render json: { error: "Phone Number and Password are required" }, status: :bad_request
    end

    unless phone_number.match?(/\A[6-9]\d{9}\z/)
      return render json: { error: "Mobile number must be exactly 10 digits and start with 6, 7, 8, or 9." }, status: :unprocessable_entity
    end

    user = User.find_by(phone_number: phone_number)

    unless user&.authenticate(password)
      return render json: { error: "Invalid phone number or password. Please try again." }, status: :unauthorized
    end

    if user.deleted?
      return render json: { error: "This account has been deleted. Please contact support." }, status: :forbidden
    end

    unless user.is_active
      return render json: {
        error: "account_inactive",
        message: "Your account has been deactivated. Please contact the administrator for assistance."
      }, status: :forbidden
    end

    unless user.phone_verified
      # Automatically send OTP when user is unverified
      otp_outcome = send_otp_to_user(user)

      return render json: {
        error: "account_unverified",
        message: "Your account verification is pending. Please verify your OTP to continue.",
        phone_number: user.phone_number,
        otp_sent: otp_outcome[:success],
        otp_message: otp_outcome[:message],
        resends_remaining: otp_outcome[:resends_remaining]
      }, status: :forbidden
    end

    token = JsonWebToken.encode({ user_id: user.id, token_version: user.token_version })
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
      token = JsonWebToken.encode({ user_id: user.id, token_version: user.token_version })
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
  # Requires the JWT issued by verify_otp in the Authorization header.
  # Identity is taken from current_user — the phone_number param is ignored.
  def reset_password
    password              = params[:password]
    password_confirmation = params[:password_confirmation]

    if password.blank? || password_confirmation.blank?
      return render json: { error: "password and password_confirmation are required" }, status: :bad_request
    end

    unless password == password_confirmation
      return render json: { error: "Password and password confirmation do not match" }, status: :unprocessable_entity
    end

    if current_user.update(password: password, password_confirmation: password_confirmation)
      render json: { message: "Password reset successful. Please login." }, status: :ok
    else
      render json: { error: current_user.errors.full_messages }, status: :unprocessable_entity
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
        :account_type
    )
  end

  def send_otp_to_user(user)
    User.transaction do
      user.lock!

      # ── 60-second cooldown between consecutive sends ───────────────────────
      last_otp = OtpCode.where(user_id: user.id).order(created_at: :desc).first
      if last_otp && last_otp.created_at > 60.seconds.ago
        remaining = (60 - (Time.current - last_otp.created_at).to_i)
        return { success: false, message: "Please wait #{remaining} seconds before requesting a new OTP.", resends_remaining: 0 }
      end

      # ── Reset 24-hour window if it has expired ────────────────────────────
      if user.otp_resend_window_start.nil? || user.otp_resend_window_start < 24.hours.ago
        user.update_columns(otp_resend_count: 0, otp_resend_window_start: Time.current)
      end

      # ── Daily limit ────────────────────────────────────────────────────────
      if user.otp_resend_count >= MAX_OTP_RESENDS_PER_DAY
        window_resets_at = user.otp_resend_window_start + 24.hours
        hours_left = ((window_resets_at - Time.current) / 3600).ceil
        return { success: false, message: "You have reached the maximum resend limit. Please try again after 24 hours.", resends_remaining: 0 }
      end

      otp = user.generate_otp
      user.increment!(:otp_resend_count)

      Rails.logger.info "OTP auto-sent during signin for #{user.phone_number}: #{otp}"
      return {
        success: true,
        message: "OTP sent to your phone number",
        otp: otp,
        resends_remaining: MAX_OTP_RESENDS_PER_DAY - user.otp_resend_count
      }
    end
  rescue StandardError => e
    Rails.logger.error "Error sending OTP to user #{user.id}: #{e.message}"
    { success: false, message: "Error sending OTP. Please try again.", resends_remaining: 0 }
  end
end
