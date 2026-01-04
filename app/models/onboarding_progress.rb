class OnboardingProgress < ApplicationRecord
	belongs_to :user
	 belongs_to :business
	 def self.ransackable_attributes(auth_object = nil)
    ["business_id", "completed", "completed_at", "created_at", "current_step", "id", "id_value", "steps_completed", "updated_at", "user_id"]
  end
end
