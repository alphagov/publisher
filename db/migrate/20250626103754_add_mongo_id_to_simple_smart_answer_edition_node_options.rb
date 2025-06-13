class AddMongoIdToSimpleSmartAnswerEditionNodeOptions < ActiveRecord::Migration[7.1]
  def change
    add_column :simple_smart_answer_edition_node_options, :mongo_id, :text
  end
end
