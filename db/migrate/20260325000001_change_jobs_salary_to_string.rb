class ChangeJobsSalaryToString < ActiveRecord::Migration[7.1]
  def up
    change_column :jobs, :salary, :string
  end

  def down
    change_column :jobs, :salary, :integer
  end
end
