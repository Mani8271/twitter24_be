# db/migrate/XXXXXX_create_users.rb
class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email
      t.boolean :email_verified, default: false
      t.boolean :phone_verified, default: false
      t.string :phone_number, null: false
      t.string :password_digest
      t.string :profile_picture
      t.string :current_location_size_id
      t.string :country_id
      t.string :region_id
      t.string :zone_location_id
      t.string :currency_pref
      t.text :followin_business, default: [].to_yaml
      t.boolean :is_online, default: false
      t.string :status
      t.string :account_type, default: "user"

      t.timestamps
    end

    add_index :users, :phone_number, unique: true
    add_index :users, :email, unique: true
  end
end
