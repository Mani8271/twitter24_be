class CreateGlobalFeeds < ActiveRecord::Migration[7.1]
  def change
    create_table :global_feeds do |t|
      t.string :title
      t.text :description
      t.string :category
      t.integer :disappear_after
      t.json :tags
      t.json :links

      t.timestamps
    end
  end
end
