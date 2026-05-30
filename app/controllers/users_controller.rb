class UsersController < ApplicationController
  # authorize_request already runs

  # GET /me
  def me
    render json: current_user, serializer: UserSerializer
  end

  # PATCH /me
  def update_me
    if current_user.update(user_params)
      begin
        attach_profile_picture
      rescue ArgumentError => e
        return render json: { errors: [e.message] }, status: :unprocessable_entity
      end
      render json: current_user, serializer: UserSerializer
    else
      render json: { errors: current_user.errors.full_messages },
             status: :unprocessable_entity
    end
  end
 #change pass
  def change_password
    unless current_user.authenticate(params[:current_password])
      return render json: { error: "Current password is incorrect" }, status: :unauthorized
    end
  
    if params[:new_password].blank?
      return render json: { error: "New password cannot be blank" }, status: :unprocessable_entity
    end
  
    if params[:new_password] != params[:password_confirmation]
      return render json: { error: "Password confirmation does not match" }, status: :unprocessable_entity
    end
  
    if current_user.update(password: params[:new_password])
      # Invalidate all existing sessions by bumping the token version.
      # The caller's current token remains valid for this request but any
      # other open sessions (other devices / tabs) will be rejected.
      current_user.increment!(:token_version)
      render json: { message: "Password updated successfully. Please log in again on other devices." }, status: :ok
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end
  def followed_businesses
    businesses = current_user.followed_businesses
    render json: businesses, each_serializer: BusinessSerializer
  end

  def delete_account
    current_user.soft_delete!
    render json: { message: "Account deleted successfully." }, status: :ok
  end

  private

  def user_params
    params.permit(
      :name,
      :email,
      :phone_number,
      :currency_pref,
      :status
    )
  end

  def attach_profile_picture
    return unless params[:profile_picture].present?

    file = params[:profile_picture]
    allowed_types = %w[image/jpeg image/png image/webp image/gif]
    max_size_bytes = 10.megabytes

    unless allowed_types.include?(file.content_type)
      raise ArgumentError, "Profile picture must be a JPEG, PNG, WebP, or GIF."
    end

    if file.size > max_size_bytes
      raise ArgumentError, "Profile picture must be 10 MB or smaller."
    end

    current_user.profile_picture.attach(file)
  end
end
