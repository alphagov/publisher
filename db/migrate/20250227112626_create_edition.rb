class CreateEdition < ActiveRecord::Migration[7.1]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
    create_table :editions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :panopticon_id
      t.integer :version_number, default: 1
      t.integer :sibling_in_progress, default: nil
      t.string :title
      t.boolean :in_beta, default: false
      t.datetime :publish_at
      t.string :overview
      t.string :slug
      t.integer :rejected_count, default: 0
      t.string :assignee
      t.string :reviewer
      t.string :creator
      t.string :publisher
      t.string :archiver
      t.boolean :major_change, default: false
      t.string :change_note
      t.string :state, default: "draft"
      t.datetime :review_requested_at
      t.uuid :auth_bypass_id, default: -> { "gen_random_uuid()" }
      t.string :owning_org_content_ids, array: true, default: []
      t.text :mongo_id
      t.timestamps

      t.index %i[panopticon_id version_number], unique: true
      t.index :state
      t.index :created_at
      t.index :updated_at

      t.references :editionable, polymorphic: true, null: false
      t.references :assigned_to, index: true, foreign_key: { to_table: :users }
    end
  end
end
