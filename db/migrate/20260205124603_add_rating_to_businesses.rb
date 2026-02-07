class AddRatingToBusinesses < ActiveRecord::Migration[7.1]
  def change
    add_column :businesses, :average_rating, :float
    add_column :businesses, :reviews_count, :integer
  end
end
