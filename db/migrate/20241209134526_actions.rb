class Actions < ActiveRecord::Migration[7.1]
  def change
    create_table :actions do |t|
      t.integer :approver_id
      t.datetime :approved
      t.string :comment
      t.boolean :comment_sanitized
      t.string :request_type
      t.json :request_details
      t.string :email_addresses
      t.string :customised_message
      t.datetime :created_at
    end
  end
end
