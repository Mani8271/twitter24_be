class LiveLocation < ApplicationRecord
  include Geocoder::Model::ActiveRecord

  belongs_to :user
    before_save :ensure_single_default, if: :live_location_default?

  reverse_geocoded_by :latitude, :longitude do |obj, results|
    if (geo = results.first)
      obj.address = geo.address
      obj.city    = geo.city
      obj.state   = geo.state
      obj.country = geo.country
    end
  end

  after_validation :reverse_geocode, if: ->(o) { o.latitude.present? && o.longitude.present? }

  private

  def ensure_single_default
    LiveLocation.where(user_id: user_id, live_location_default: true)
                .where.not(id: id)
                .update_all(live_location_default: false)
  end
end
