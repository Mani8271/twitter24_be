class GlobalFeed < ApplicationRecord
  belongs_to :user, optional: true
  has_many_attached :media
  
  has_many :likes, as: :likeable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :views, as: :viewable, dependent: :destroy

  validates :title, presence: true
  validates :category, presence: true

  validates :feed_type, inclusion: { in: %w[global local] }

  validates :latitude, :longitude, :reach_distance,
            presence: true,
            if: -> { feed_type == "local" }

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
    def self.ransackable_associations(auth_object = nil)
    ["media_attachments", "media_blobs", "user"]
  end
    def self.ransackable_attributes(auth_object = nil)
    ["address", "category", "created_at", "description", "disappear_after", "feed_type", "id", "id_value", "latitude", "links", "longitude", "reach_distance", "tags", "title", "updated_at", "user_id"]
  end
end
