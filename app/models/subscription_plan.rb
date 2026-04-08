class SubscriptionPlan < ApplicationRecord
  # Machine-readable keys stored in the `features` DB column.
  # Admin adds/removes these via checkboxes — no hardcoded plan mapping needed.
  FEATURES = %w[
    global_feed
    local_feed
    job_posts
    offers
    post_radius
    domain_page
    post_anywhere
    global_search
    domain_uploads
  ].freeze

  # All features support limits and ranges — admin decides which ones to set.
  LIMITABLE_FEATURES = FEATURES.freeze
  RANGEABLE_FEATURES = FEATURES.freeze

  # Human-readable labels shown in the admin UI and API responses.
  FEATURE_LABELS = {
    "global_feed"    => "Global Feed",
    "local_feed"     => "Local Feed",
    "job_posts"      => "Job Posts",
    "offers"         => "Offers",
    "post_radius"    => "Post by Radius",
    "domain_page"    => "Domain Page",
    "post_anywhere"  => "Post from Any Location",
    "global_search"  => "Global Search Visibility",
    "domain_uploads" => "Domain Uploads"
  }.freeze

  has_many :users, foreign_key: :subscription_plan_id, dependent: :nullify

  validates :plan_type, presence: true, uniqueness: true
  validates :features,  presence: true
  validates :amounts,   presence: true
  validates :position,  presence: true,
                        numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate  :features_must_be_valid_keys

  before_save :strip_blank_limits_and_ranges

  scope :active, -> { where(is_active: true).order(:position) }

  # Returns true if this plan includes the given feature key.
  def has_feature?(feature_key)
    features.include?(feature_key.to_s)
  end

  # Returns the numeric post limit for a feature, or nil if unlimited.
  def limit_for(feature_key)
    return nil unless has_feature?(feature_key)
    val = limits[feature_key.to_s]
    val.present? ? val.to_i : nil
  end

  # Returns the geographic range in km for a feature, or nil if unlimited.
  def range_for(feature_key)
    return nil unless has_feature?(feature_key)
    val = ranges[feature_key.to_s]
    val.present? ? val.to_i : nil
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[amounts created_at features id is_active limits ranges plan_type position updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[users]
  end

  private

  def features_must_be_valid_keys
    invalid = Array(features) - FEATURES
    errors.add(:features, "contains invalid keys: #{invalid.join(', ')}") if invalid.any?
  end

  # Remove blank/zero entries so nil = truly unlimited, not submitted-but-empty
  def strip_blank_limits_and_ranges
    self.limits = (limits || {}).reject { |_, v| v.to_s.strip.blank? }
    self.ranges = (ranges || {}).reject { |_, v| v.to_s.strip.blank? }
  end
end
