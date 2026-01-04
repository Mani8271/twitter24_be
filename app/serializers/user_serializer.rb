class UserSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id,
             :name,
             :email,
             :phone_number,
             :profile_picture,
             :currency_pref,
             :status,
             :is_online,
             :account_type,
             :email_verified,
             :phone_verified

  # def profile_picture
  #   return nil unless object.profile_picture.attached?
  #   rails_blob_url(object.profile_picture, only_path: true)
  # end
    def profile_picture
    return nil unless object.profile_picture.attached?
    rails_blob_url(object.profile_picture)
  end
end
