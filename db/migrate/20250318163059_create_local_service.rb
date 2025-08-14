class CreateLocalService < ActiveRecord::Migration[7.1]
  def change
    create_table :local_services do |t|
      t.string :description
      t.integer :lgsl_code
      t.text :mongo_id
      t.string :providing_tier, array: true, default: []
      t.timestamps
    end
  end
end
