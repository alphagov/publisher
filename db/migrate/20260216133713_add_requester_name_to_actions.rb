class AddRequesterNameToActions < ActiveRecord::Migration[8.1]
  def change
    add_column :actions, :requester_name, :string, null: true
  end
end
