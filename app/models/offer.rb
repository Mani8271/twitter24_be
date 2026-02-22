class Offer < ApplicationRecord
  belongs_to :user
  has_one_attached :media

  validates :title, :description, :offer_type, presence: true
  validates :offer_type, inclusion: { in: %w[local global] }

  validate :validate_links_format
  validate :location_required_for_local

  scope :active, -> { where("valid_till IS NULL OR valid_till >= ?", Time.current) }
  scope :by_type, ->(type) { where(offer_type: type) if type.present? }

  private

  def validate_links_format
    return if links.blank?

    unless links.is_a?(Array)
      errors.add(:links, "must be an array")
      return
    end

    links.each do |link|
      unless link["button_name"].present? && link["url"].present?
        errors.add(:links, "each link must contain button_name and url")
      end
    end
  end

  def location_required_for_local
    if offer_type == "local" && (latitude.blank? || longitude.blank?)
      errors.add(:base, "Location required for local offers")
    end
  end
end