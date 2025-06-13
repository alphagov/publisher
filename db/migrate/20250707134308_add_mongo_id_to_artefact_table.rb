class AddMongoIdToArtefactTable < ActiveRecord::Migration[7.1]
  def change
    add_column :artefacts, :mongo_id, :text
  end
end
