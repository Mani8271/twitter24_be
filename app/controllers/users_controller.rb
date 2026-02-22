class UsersController < ApplicationController
  # authorize_request already runs

  # GET /me
  def me
    render json: current_user, serializer: UserSerializer
  end

  # PATCH /me
  def update_me
    if current_user.update(user_params)
      attach_profile_picture
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
      render json: { message: "Password updated successfully" }, status: :ok
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end
  def followed_businesses
    businesses = current_user.followed_businesses
    render json: businesses, each_serializer: BusinessSerializer
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
    current_user.profile_picture.attach(params[:profile_picture])
  end
end
