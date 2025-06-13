class CreateDowntime < ActiveRecord::Migration[7.1]
  def change
    create_table :downtimes do |t|
      t.string :message
      t.datetime :start_time
      t.datetime :end_time
      t.references :artefact, foreign_key: true
      t.timestamps
    end
  end
end
