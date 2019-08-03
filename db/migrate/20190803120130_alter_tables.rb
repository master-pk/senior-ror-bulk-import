class AlterTables < ActiveRecord::Migration[5.2]
  def change
    change_column_null :employees, :email, false
    add_index :employees, :email, unique: true
  end
end
