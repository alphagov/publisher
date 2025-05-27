class CreatePlaceEdition < ActiveRecord::Migration[7.1]
  def change
    create_table :place_editions do |t|
      t.string :introduction
      t.string :more_information
      t.string :need_to_know
      t.string :place_type
      t.timestamps
    end
  end
end
