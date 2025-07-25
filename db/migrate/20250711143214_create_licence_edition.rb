class CreateLicenceEdition < ActiveRecord::Migration[7.1]
  def change
    create_table :licence_editions do |t|
      t.string :licence_identifier
      t.string :licence_short_description
      t.string :licence_overview
      t.string :will_continue_on
      t.string :continuation_link
      t.timestamps
    end
  end
end
