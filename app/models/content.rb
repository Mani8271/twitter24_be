class Content < ApplicationRecord
	  def self.ransackable_attributes(auth_object = nil)
    ["content", "created_at", "id", "id_value", "subtitle", "title", "updated_at"]
  end
end
