class AddPostTypeToJobs < ActiveRecord::Migration[7.1]
  def change
    add_column :jobs, :post_type, :string, default: "local", null: false
    add_index :jobs, :post_type
  end
end
