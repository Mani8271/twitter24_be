class Category < ApplicationRecord
      def self.ransackable_attributes(auth_object = nil)
    ["created_at", "emoji", "id", "id_value", "is_active", "name", "priority", "updated_at"]
  end
end
