class AddMongoIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :mongo_id, :text
  end
end
