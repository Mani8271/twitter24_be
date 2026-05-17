class AddTokenVersionToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :token_version, :integer, default: 0, null: false
  end
end
