class CreateArtefactExternalLink < ActiveRecord::Migration[7.1]
  def change
    create_table :artefact_external_links do |t|
      t.text :mongo_id
      t.string :title
      t.string :url
      t.references :artefact, foreign_key: true
    end
  end
end
