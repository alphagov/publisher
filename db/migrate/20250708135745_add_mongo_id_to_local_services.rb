class AddMongoIdToLocalServices < ActiveRecord::Migration[7.1]
  def change
    add_column :local_services, :mongo_id, :text
  end
end
