class CreateArtefactExternalLink < ActiveRecord::Migration[7.1]
  def change
    create_table :artefact_external_links do |t|
      t.string :title
      t.string :url
      t.references :artefact, foreign_key: true
      t.timestamps
    end
  end
end
