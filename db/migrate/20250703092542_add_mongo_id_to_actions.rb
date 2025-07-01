class AddMongoIdToActions < ActiveRecord::Migration[7.1]
  def change
    add_column :actions, :mongo_id, :text
  end
end
