class CreateViews < ActiveRecord::Migration[7.1]
  def change
    create_table :views do |t|
      t.references :user, null: false, foreign_key: true
      t.references :viewable, polymorphic: true, null: false

      t.timestamps
    end
    add_index :views, [:user_id, :viewable_type, :viewable_id], unique: true

  end
end
