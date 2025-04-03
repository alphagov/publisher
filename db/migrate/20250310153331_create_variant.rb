class CreateVariant < ActiveRecord::Migration[7.1]
  def change
    create_table :variants do |t|
      t.integer :order
      t.string :title
      t.string :slug
      t.string :introduction
      t.string :link
      t.string :more_information
      t.string :alternate_methods
      t.timestamps

      t.references :transaction_edition, foreign_key: true
    end
  end
end
