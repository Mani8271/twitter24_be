class AddRejectionReasonToBusinesses < ActiveRecord::Migration[7.1]
  def change
    add_column :businesses, :rejection_reason, :text
  end
end
