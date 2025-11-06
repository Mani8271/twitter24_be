class CreateContents < ActiveRecord::Migration[7.1]
  def change
    create_table :contents do |t|
      t.string :title
      t.string :subtitle
      t.text :content

      t.timestamps
    end
  end
end
