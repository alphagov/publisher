class AddMongoIdToDevolvedAdministrationAvailability < ActiveRecord::Migration[7.1]
  def change
    add_column :devolved_administration_availabilities, :mongo_id, :text
  end
end
