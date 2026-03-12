class Business < ApplicationRecord
  belongs_to :user

  has_one :business_contact, dependent: :destroy
  has_one :business_location, dependent: :destroy
  has_one :business_document, dependent: :destroy
  has_many :business_hours, dependent: :destroy

  # ActiveStorage (Step 6)
  has_one_attached :profile_picture
  has_many_attached :shop_images
  has_many :reviews, dependent: :destroy

  has_many :global_feeds, through: :user

  

  # Convenience methods to check favorite status
  def favorited_by?(user)
    likes.exists?(user_id: user.id)
  end

  def favorites_count
    likes.count
  end
    has_many :likes, as: :likeable, dependent: :destroy
  has_many :favorited_by_users, through: :likes, source: :user
    has_many :follows, as: :followable, dependent: :destroy
  has_many :followers, through: :follows, source: :user

  def followed_by?(user)
    follows.exists?(user_id: user.id)
  end

  def followers_count
    follows.count
  end
  
  def self.ransackable_attributes(auth_object = nil)
    %w[id name category status about year_established website user_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[user business_contact business_location business_hours business_document]
  end
end

