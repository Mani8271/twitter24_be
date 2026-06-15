class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.string :name
      t.string :emoji
      t.integer :priority
      t.boolean :is_active

      t.timestamps
    end
  end
end
