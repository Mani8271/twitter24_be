class CreateBusinessUpgradeRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :business_upgrade_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.string     :request_status, null: false, default: "pending"
      t.datetime   :requested_at,   null: false
      t.string     :approved_by
      t.datetime   :approved_at
      t.text       :rejection_reason

      t.timestamps
    end

    add_index :business_upgrade_requests, :request_status
    add_index :business_upgrade_requests, [:user_id, :request_status], name: "index_bur_on_user_and_status"
  end
end
