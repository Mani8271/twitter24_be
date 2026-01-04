ActiveAdmin.register OnboardingProgress do
  menu label: "Onboarding"

  permit_params :user_id, :business_id, :current_step, :completed, :completed_at, steps_completed: []

  filter :completed
  filter :current_step
  filter :user_id
  filter :business_id
  filter :created_at

  index do
    selectable_column
    id_column
    column :user_id
    column :business_id
    column :current_step
    column :completed
    column :completed_at
    column :created_at
    actions
  end
end
