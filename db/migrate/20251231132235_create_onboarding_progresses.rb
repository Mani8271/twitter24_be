class CreateOnboardingProgresses < ActiveRecord::Migration[7.1]
  def change
    create_table :onboarding_progresses do |t|
      t.integer :user_id
      t.integer :business_id  # Add the business_id column here
      t.integer :current_step
      t.jsonb :steps_completed
      t.boolean :completed
      t.datetime :completed_at

      t.timestamps
    end

    add_index :onboarding_progresses, :user_id, unique: true
    add_index :onboarding_progresses, :business_id  # Index for business_id without uniqueness
    add_foreign_key :onboarding_progresses, :users
    add_foreign_key :onboarding_progresses, :businesses  # Add foreign key for business_id
  end
end
