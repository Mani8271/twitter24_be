class ChangeIsNewBusinessUserDefaultToFalse < ActiveRecord::Migration[7.0]
  def change
    change_column_default :users, :is_new_business_user, from: true, to: false
  end
end
