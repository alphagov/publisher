class CreateVariant < ActiveRecord::Migration[7.1]
  def change
    create_table :variants do |t|
      t.text :mongo_id
      t.integer :order
      t.string :title
      t.string :slug
      t.string :introduction
      t.string :link
      t.string :more_information
      t.string :alternate_methods
      t.timestamps
    end
  end
end
