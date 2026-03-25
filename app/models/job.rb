class Job < ApplicationRecord
  belongs_to :user
  has_many_attached :images

  validates :job_title, :description, presence: true
  validates :job_type, inclusion: { in: %w[full_time part_time contract internship freelance] }, allow_blank: true

  validate :validate_links_format

  scope :active, -> {
    where(
      "disappearing_days IS NULL OR created_at >= ?",
      Time.current - (Arel.sql("disappearing_days || ' days'"))
    )
  }
  scope :by_type,       ->(type)  { where(job_type: type) if type.present? }
  scope :by_experience, ->(exp)   { where(experience: exp) if exp.present? }
  scope :by_search, ->(query) {
    if query.present?
      term = "%#{query.downcase}%"
      where(
        "LOWER(job_title) LIKE :q OR LOWER(description) LIKE :q OR LOWER(skills_required) LIKE :q OR LOWER(location_name) LIKE :q",
        q: term
      )
    end
  }
  scope :by_salary_min, ->(min)  { where("salary >= ?", min.to_i) if min.present? }
  scope :by_salary_max, ->(max)  { where("salary <= ?", max.to_i) if max.present? }
  scope :sorted_by, ->(sort) {
    case sort
    when "newest"      then order(created_at: :desc)
    when "oldest"      then order(created_at: :asc)
    when "salary_asc"  then order(Arel.sql("COALESCE(salary,0) ASC"))
    when "salary_desc" then order(Arel.sql("COALESCE(salary,0) DESC"))
    else order(created_at: :desc)
    end
  }
  scope :nearby, ->(lat, lng, km) {
    where(
      "earth_box(ll_to_earth(?, ?), ?) @> ll_to_earth(latitude, longitude)",
      lat, lng, km * 1000
    )
  }

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at description disappearing_days experience id job_title job_type
       latitude links location_name longitude post_type reach_distance salary
       skills_required tags updated_at user_id working_hours]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[user]
  end

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
end
