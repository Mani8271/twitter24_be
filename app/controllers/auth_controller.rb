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

  # POST /send_otp
  def send_otp
    phone_number = params[:phone_number]
    return render(json: { error: "phone_number is required" }, status: :bad_request) if phone_number.blank?

    user = User.find_by(phone_number: phone_number)
    return render(json: { error: "User not found. Please sign up first." }, status: :not_found) unless user

    otp = user.generate_otp
    Rails.logger.info "🚨 OTP sent to #{user.phone_number}: #{otp}"

    render json: { 
      message: "OTP sent to #{user.phone_number}",
      otp: otp
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
      :email_verified,     
      :phone_verified 
    )
  end
end
