class AddMongoIdToParts < ActiveRecord::Migration[7.1]
  def change
    add_column :parts, :mongo_id, :text
  end
end
