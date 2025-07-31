class CreateArtefact < ActiveRecord::Migration[7.1]
  def change
    create_table :artefacts do |t|
      t.string :name
      t.string :slug
      t.string :paths, array: true, default: []
      t.string :prefixes, array: true, default: []
      t.string :kind
      t.string :owning_app
      t.string :rendering_app
      t.boolean :active, default: false
      t.string :publication_id
      t.string :description
      t.string :state, default: "draft"
      t.string :language, default: "en"
      t.string :latest_change_note
      t.datetime :public_timestamp
      t.string :redirect_url
      t.string :content_id
      t.text :mongo_id
      t.timestamps
      t.index %i[name state kind id]
      t.index :slug, unique: true
    end
  end
end
