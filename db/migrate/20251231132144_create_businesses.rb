class CreateBusinesses < ActiveRecord::Migration[7.1]
  def change
    create_table :businesses do |t|
      t.integer :user_id
      t.string :name
      t.string :category
      t.integer :year_established
      t.string :website
      t.text :about
      t.jsonb :products_services
      t.string :status

      t.timestamps
    end
    add_index :businesses, :user_id, unique: true
   add_foreign_key :businesses, :users
  end
end
