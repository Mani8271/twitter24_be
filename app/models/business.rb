class Business < ApplicationRecord
  CATEGORIES = [
    "Food & Dining",
    "Groceries",
    "Electronics",
    "Fashion & Apparel",
    "Beauty & Wellness",
    "Fitness & Sports",
    "Healthcare",
    "Education",
    "Services",
    "Retail",
    "Real Estate",
    "Automobiles",
    "Hotels & Travel",
    "Entertainment",
    "Finance",
  ].freeze

  has_paper_trail only: [:status, :rejection_reason]

  before_destroy :cleanup_media

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

  private

  def cleanup_media
    # Direct deletion from S3 when business is destroyed
    if profile_picture.attached?
      profile_picture.purge
      Rails.logger.info("Business #{id}: Deleted profile picture from S3")
    end
    if shop_images.attached?
      shop_images.purge
      Rails.logger.info("Business #{id}: Deleted #{shop_images.count} shop images from S3")
    end
  end

  public

  def self.ransackable_attributes(auth_object = nil)
    %w[id name category keywords status about year_established website user_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[user business_contact business_location business_hours business_document]
  end
end

