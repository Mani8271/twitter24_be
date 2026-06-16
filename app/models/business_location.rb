class BusinessLocation < ApplicationRecord
  include AddressCooldown

  belongs_to :business

  before_save :update_address_timestamp, if: -> { address_changed? }

  reverse_geocoded_by :latitude, :longitude

  private

  def update_address_timestamp
    self.address_last_updated_at = Time.current
  end
end
