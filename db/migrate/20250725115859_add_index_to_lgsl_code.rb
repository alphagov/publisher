class AddIndexToLgslCode < ActiveRecord::Migration[7.1]
  def change
    add_index :local_services, :lgsl_code, unique: true
  end
end
