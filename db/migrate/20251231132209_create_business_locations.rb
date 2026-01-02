class CreateBusinessLocations < ActiveRecord::Migration[7.1]
  def change
    create_table :business_locations do |t|
      t.integer :business_id
      t.string :map_address
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :place_id
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :state
      t.string :pin_code

      t.timestamps
    end
    add_index :business_locations, :business_id, unique: true
add_foreign_key :business_locations, :businesses

  end
end
