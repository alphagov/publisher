class CreateSimpleSmartAnswerEditionNodeOption < ActiveRecord::Migration[7.1]
  def change
    create_table :simple_smart_answer_edition_node_options do |t|
      t.string :label
      t.string :slug
      t.string :next_node
      t.integer :order
      t.text :mongo_id
      t.references :node, foreign_key: { to_table: :simple_smart_answer_edition_nodes }
    end
  end
end
