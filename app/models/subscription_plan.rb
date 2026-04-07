class SubscriptionPlan < ApplicationRecord
  has_many :users, foreign_key: :subscription_plan_id, dependent: :nullify

  validates :plan_type, presence: true, uniqueness: true
  validates :features,  presence: true
  validates :amounts,   presence: true
  validates :position,  presence: true,
                        numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(is_active: true).order(:position) }

  def self.ransackable_attributes(auth_object = nil)
    %w[amounts created_at features id is_active plan_type position updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[users]
  end
end
