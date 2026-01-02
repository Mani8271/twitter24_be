class GlobalFeed < ApplicationRecord
  has_many_attached :media

  # Basic validations
  validates :title, presence: true
  validates :category, presence: true

  validate :tags_array
  validate :links_array_structure

  private

  def tags_array
    return if tags.blank?
    errors.add(:tags, "must be an array") unless tags.is_a?(Array)
  end

  def links_array_structure
    return if links.blank?

    unless links.is_a?(Array)
      errors.add(:links, "must be an array")
      return
    end

    links.each do |link|
      unless link.is_a?(Hash) &&
             link["name"].present? &&
             link["url"].present?
        errors.add(:links, "each link must contain name and url")
      end
    end
  end
end
