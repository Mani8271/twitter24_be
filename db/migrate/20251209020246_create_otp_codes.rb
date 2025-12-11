# db/migrate/xxx_create_otp_codes.rb
class CreateOtpCodes < ActiveRecord::Migration[7.0]
  def change
    create_table :otp_codes do |t|
      t.string :user_id, null: false  
      t.string :phone_number, null: false
      t.string :otp_number, null: false
      t.datetime :otp_expiry, null: false

      t.timestamps
    end

    add_index :otp_codes, :user_id
    add_index :otp_codes, :phone_number
    add_index :otp_codes, :otp_number, unique: true
  end
end