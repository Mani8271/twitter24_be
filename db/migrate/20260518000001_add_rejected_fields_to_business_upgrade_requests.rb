class AddRejectedFieldsToBusinessUpgradeRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :business_upgrade_requests, :rejected_by, :string
    add_column :business_upgrade_requests, :rejected_at, :datetime
  end
end
