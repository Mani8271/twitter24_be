class BusinessLocation < ApplicationRecord
	 belongs_to :business
	

	 reverse_geocoded_by :latitude, :longitude
end
