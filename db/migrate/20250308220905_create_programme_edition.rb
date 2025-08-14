class CreateProgrammeEdition < ActiveRecord::Migration[7.1]
  def change
    create_table :programme_editions do |t|

      t.timestamps
    end
  end
end
