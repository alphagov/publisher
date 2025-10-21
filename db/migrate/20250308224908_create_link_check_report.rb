class CreateLinkCheckReport < ActiveRecord::Migration[7.1]
  def change
    create_table :link_check_reports do |t|
      t.text :mongo_id
      t.integer :batch_id
      t.string :status
      t.datetime :completed_at

      t.references :edition, foreign_key: true, type: :uuid
      t.timestamps
    end
  end
end
