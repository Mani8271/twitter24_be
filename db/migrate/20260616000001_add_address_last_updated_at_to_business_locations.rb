class AddAddressLastUpdatedAtToBusinessLocations < ActiveRecord::Migration[7.1]
  def change
    add_column :business_locations, :address_last_updated_at, :datetime, default: -> { 'CURRENT_TIMESTAMP' }
  end
end
