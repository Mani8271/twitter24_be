class AddAddressToBusinessContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :business_contacts, :address_line1, :string
    add_column :business_contacts, :address_line2, :string
    add_column :business_contacts, :city,          :string
    add_column :business_contacts, :state,         :string
    add_column :business_contacts, :pincode,       :string
  end
end
