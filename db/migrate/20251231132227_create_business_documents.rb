class CreateBusinessDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :business_documents do |t|
      t.integer :business_id
      t.boolean :has_gstin
      t.string :gstin
      t.boolean :has_pan
      t.string :pan
      t.boolean :has_fssai
      t.string :fssai

      t.timestamps
    end
    add_index :business_documents, :business_id, unique: true
add_foreign_key :business_documents, :businesses

  end
end
