class AddKeywordsAndVideoLinksToBusinesses < ActiveRecord::Migration[7.1]
  def change
    add_column :businesses, :keywords,    :text, array: true, default: []
    add_column :businesses, :video_links, :text, array: true, default: []
  end
end
