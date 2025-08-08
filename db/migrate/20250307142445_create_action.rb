class CreateAction < ActiveRecord::Migration[7.1]
  def change
    create_table :actions do |t|
      t.integer :approver_id
      t.datetime :approved
      t.string :comment
      t.boolean :comment_sanitized, default: false
      t.string :request_type
      t.jsonb :request_details, default: {}
      t.string :email_addresses
      t.string :customised_message
      t.text :mongo_id
      t.timestamps

      t.references :edition, foreign_key: true, type: :uuid
      t.references :requester, foreign_key: { to_table: :users }
      t.references :recipient, foreign_key: { to_table: :users }
    end
  end
end
