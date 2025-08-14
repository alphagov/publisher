class CreateDevolvedAdministrationAvailability < ActiveRecord::Migration[7.1]
  def change
    create_table :devolved_administration_availabilities do |t|
      t.string :authority_type, default: "local_authority_service"
      t.string :alternative_url
      t.string :type
      t.text :mongo_id
      t.references :local_transaction_edition, foreign_key: true
      t.timestamps
    end
  end
end
