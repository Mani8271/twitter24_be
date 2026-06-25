class AddUsedAtToOtpCodes < ActiveRecord::Migration[7.1]
  def change
    add_column :otp_codes, :used_at, :datetime, null: true
    add_index :otp_codes, [:user_id, :used_at], name: "index_otp_codes_user_used_status"
  end
end
