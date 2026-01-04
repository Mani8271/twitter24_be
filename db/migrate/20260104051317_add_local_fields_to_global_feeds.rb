class AddLocalFieldsToGlobalFeeds < ActiveRecord::Migration[7.1]
  def change
    add_column :global_feeds, :feed_type, :string, null: false, default: "global"

    # location fields
    add_column :global_feeds, :latitude, :float
    add_column :global_feeds, :longitude, :float
    add_column :global_feeds, :address, :string
     add_column :global_feeds, :user_id, :integer
    add_index :global_feeds, :user_id

    # radius in KM
    add_column :global_feeds, :reach_distance, :integer

    add_index :global_feeds, :feed_type
    add_index :global_feeds, [:latitude, :longitude]
  end
end
