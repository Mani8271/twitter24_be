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
