class Business < ApplicationRecord
  belongs_to :user

  has_one :business_contact, dependent: :destroy
  has_one :business_location, dependent: :destroy
  has_one :business_document, dependent: :destroy
  has_many :business_hours, dependent: :destroy

  # ActiveStorage (Step 6)
  has_one_attached :profile_picture
  has_many_attached :shop_images
end

