class CreateBusinessHours < ActiveRecord::Migration[7.1]
  def change
    create_table :business_hours do |t|
      t.integer :business_id
      t.integer :day_of_week
      t.boolean :is_open
      t.time :opens_at
      t.time :closes_at

      t.timestamps
    end
    add_index :business_hours, [:business_id, :day_of_week], unique: true
add_foreign_key :business_hours, :businesses
  end
end
