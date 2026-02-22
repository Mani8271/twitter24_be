class CreateOffers < ActiveRecord::Migration[7.1]
  def change
    create_table :offers do |t|
      t.string  :title, null: false
      t.text    :description, null: false
      t.string  :offer_type, null: false, default: "global"

      # Location fields
      t.float   :latitude
      t.float   :longitude
      t.string  :address
      t.integer :reach_distance

      t.datetime :valid_till
      t.string   :tags
      t.integer  :disappearing_days

      t.jsonb    :links, default: []

      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :offers, :offer_type
    add_index :offers, [:latitude, :longitude]
    add_index :offers, :valid_till
  end
end