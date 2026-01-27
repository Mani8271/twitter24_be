class CreateReachDistanceSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :reach_distance_settings do |t|
    
      t.text :ranges
      t.boolean :is_active

      t.timestamps
    end
  end
end
