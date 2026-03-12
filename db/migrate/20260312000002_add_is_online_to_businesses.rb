class AddIsOnlineToBusinesses < ActiveRecord::Migration[7.1]
  def change
    add_column :businesses, :is_online, :boolean, default: false, null: false
  end
end
