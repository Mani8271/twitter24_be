class CreateLiveLocations < ActiveRecord::Migration[7.1]
  def change
    create_table :live_locations do |t|
      t.references :user, null: false, foreign_key: true
      t.float :latitude
      t.float :longitude
      t.string :address
      t.string :city
      t.string :state
      t.string :country
      t.boolean :live_location_default, default: false, null: false

      t.timestamps
    end
      add_index :live_locations, [:user_id, :live_location_default]
  end
end
