class AddMongoIdToArtefactAction < ActiveRecord::Migration[7.1]
  def change
    add_column :artefact_actions, :mongo_id, :text
  end
end
