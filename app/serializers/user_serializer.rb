# class UserSerializer < ActiveModel::Serializer
#   include Rails.application.routes.url_helpers

#   attributes :id,
#              :name,
#              :email,
#              :phone_number,
#              :profile_picture,
#              :currency_pref,
#              :status,
#              :is_online,
#              :account_type,
#              :email_verified,
#              :phone_verified
#              :followed_businesses_count

           

#   # def profile_picture
#   #   return nil unless object.profile_picture.attached?
#   #   rails_blob_url(object.profile_picture, only_path: true)
#   # end
#     def profile_picture
#     return nil unless object.profile_picture.attached?
#     rails_blob_url(object.profile_picture)
#     end
#     def followed_businesses_count
#       object.followed_businesses.count
#     end
# end

# class UserSerializer < ActiveModel::Serializer
#   include Rails.application.routes.url_helpers
#   attributes :id,
#              :name,
#              :email,
#              :phone_number,
#              :profile_picture,
#              :currency_pref,
#              :status,
#              :is_online,
#              :account_type,
#              :email_verified,
#              :phone_verified,
#              :followed_businesses_count,
#              :status

#   has_many :followed_businesses   

#   def profile_picture
#     return nil unless object.profile_picture.attached?

#     rails_blob_url(
#       object.profile_picture,
#       host: ENV["APP_HOST"] || "twitter24-be.onrender.com"
#     )
#   end
  

#   def followed_businesses_count
#     object.followed_businesses.count
#   end

#   def status
#     object.business&.status if object.account_type == "business"
#   end
  
# end


class UserSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id,
             :name,
             :email,
             :phone_number,
             :profile_picture,
             :currency_pref,
             :is_online,
             :account_type,
             :email_verified,
             :phone_verified,
             :followed_businesses_count

  # ✅ Only for business accounts
  attribute :status, if: :business_account?
  attribute :onboarding_completed, if: :business_account?
  attribute :current_step, if: :business_account?
  attribute :steps_completed, if: :business_account?

  has_many :followed_businesses   

  # -------------------------------
  # Conditions
  # -------------------------------
  def business_account?
    object.account_type == "business"
  end

  # -------------------------------
  # Business Status
  # -------------------------------
  def status
    object.business&.status
  end

  # -------------------------------
  # Onboarding Info
  # -------------------------------
  def onboarding_completed
    object.onboarding_progress&.completed || false
  end

  def current_step
    object.onboarding_progress&.current_step
  end

  def steps_completed
    object.onboarding_progress&.steps_completed || []
  end

  # -------------------------------
  # Other Methods
  # -------------------------------
  def profile_picture
    return nil unless object.profile_picture.attached?

    rails_blob_url(
      object.profile_picture,
      host: ENV["APP_HOST"] || "twitter24-be.onrender.com"
    )
  end

  def followed_businesses_count
    object.followed_businesses.count
  end
end

