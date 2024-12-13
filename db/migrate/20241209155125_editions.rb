class Editions < ActiveRecord::Migration[7.1]
  def change
    create_table :editions do |t|
      t.string :panopticon_id
      t.integer :version_number, default: 1
      # t.references :editionable, polymorphic: true, null: false
      t.integer :sibling_in_progress

      t.string :title
      t.boolean :in_beta, default: false
      t.datetime :created_at
      t.datetime :publish_at
      t.string :overview
      t.string :slug
      t.integer :rejected_count, default: 0
      t.string :assignee
      t.string :state
      t.string :reviewer
      t.string :creator
      t.string :publisher
      t.string :archiver
      t.boolean :major_change, default: false
      t.string :change_note
      t.datetime :review_requested_at
      t.string :auth_bypass_id, default: SecureRandom.uuid
      t.string "owning_org_content_ids", type: Array
      t.jsonb :edition_specific_content, null: false, default: '{}'

      t.index :panopticon_id
      t.index :version_number
      t.index :created_at
    end
  end
end
