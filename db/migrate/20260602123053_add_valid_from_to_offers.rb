class AddValidFromToOffers < ActiveRecord::Migration[7.1]
  def change
    add_column :offers, :valid_from, :datetime
  end
end
