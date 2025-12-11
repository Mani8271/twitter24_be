class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :phone_number, :profile_picture,
              :currency_pref, :status, :is_online, :account_type, :email_verified,
              :phone_verified
end
