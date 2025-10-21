class CreateSimpleSmartAnswerEditionNode < ActiveRecord::Migration[7.1]
  def change
    create_table :simple_smart_answer_edition_nodes do |t|
      t.string :slug
      t.string :title
      t.text :body
      t.integer :order
      t.string :kind
      t.text :mongo_id
      t.references :simple_smart_answer_edition,  foreign_key: { to_table: :simple_smart_answer_editions }
    end
  end
end
