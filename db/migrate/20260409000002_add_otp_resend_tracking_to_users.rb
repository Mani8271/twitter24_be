class AddOtpResendTrackingToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :otp_resend_count, :integer, default: 0, null: false
    add_column :users, :otp_resend_window_start, :datetime
  end
end
