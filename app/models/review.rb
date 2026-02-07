class Review < ApplicationRecord
  belongs_to :user
  belongs_to :business

  validates :rating, inclusion: { in: 1..5 }
  validates :comment, presence: true

  after_save :update_business_rating
  after_destroy :update_business_rating

  private

  def update_business_rating
    business.update_columns(
      average_rating: business.reviews.average(:rating)&.round(2) || 0,
      reviews_count: business.reviews.count
    )
  end
end
