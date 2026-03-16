class CreateJobs < ActiveRecord::Migration[7.1]
  def change
    create_table :jobs do |t|
      t.references :user, null: false, foreign_key: true

      t.string  :location_name
      t.decimal :latitude,  precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.integer :reach_distance

      t.string  :job_title,     null: false
      t.integer :salary
      t.string  :experience
      t.string  :job_type
      t.string  :working_hours
      t.text    :description
      t.text    :skills_required
      t.jsonb   :links,          default: []
      t.string  :tags
      t.integer :disappearing_days

      t.timestamps
    end

    add_index :jobs, :job_type
    add_index :jobs, :created_at
    add_index :jobs, :links, using: :gin
  end
end
