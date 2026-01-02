class CreateBusinessContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :business_contacts do |t|
      t.integer :business_id
      t.string :contact_person_name
      t.string :contact_phone
      t.boolean :contact_phone_verified
      t.string :contact_email
      t.string :owner_name
      t.string :owner_phone
      t.boolean :owner_phone_verified
      t.string :owner_email

      t.timestamps
    end
    add_index :business_contacts, :business_id, unique: true
    add_foreign_key :business_contacts, :businesses

  end
end
