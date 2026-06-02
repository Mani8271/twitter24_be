class AddIsNewBusinessUserToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :is_new_business_user, :boolean, default: false
  end
end
