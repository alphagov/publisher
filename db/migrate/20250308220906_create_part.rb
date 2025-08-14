class CreatePart < ActiveRecord::Migration[7.1]
  def change
    create_table :parts do |t|
      t.text :mongo_id
      t.integer :order
      t.string :title
      t.string :body
      t.string :slug
      t.references :guide_edition, foreign_key: true
      t.references :programme_edition, foreign_key: true
      t.datetime :created_at
    end
  end
end
