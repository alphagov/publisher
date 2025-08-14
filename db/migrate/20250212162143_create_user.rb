class CreateUser < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string   :name
      t.string   :email
      t.string   :uid
      t.string   :organisation_slug
      t.string   :organisation_content_id
      t.string   :app_name
      t.string   :permissions, array: true, default: []
      t.boolean  :remotely_signed_out, default: false
      t.boolean  :disabled, default: false
      t.text :mongo_id
      t.timestamps
      t.index :disabled
    end
  end
end
