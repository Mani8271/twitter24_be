class ReachDistanceSetting < ApplicationRecord
  validates :ranges, presence: true
  validate :validate_ranges_format

  def ranges_array
    (ranges || "")
      .split(",")
      .map { |x| x.to_f }
      .select { |x| x > 0 }
      .uniq
      .sort
  end

  def ranges_array=(arr)
    cleaned =
      Array(arr)
        .map { |x| x.to_f }
        .select { |x| x > 0 }
        .uniq
        .sort

    self.ranges = cleaned.join(",")
  end

  private

  def validate_ranges_format
    errors.add(:ranges, "must contain at least one valid km value like 5,10,15") if ranges_array.empty?
  end
    def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "is_active", "ranges", "updated_at"]
  end
end
