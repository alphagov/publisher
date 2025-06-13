class AddMongoIdToSimpleSmartAnswerEditionNodes < ActiveRecord::Migration[7.1]
  def change
    add_column :simple_smart_answer_edition_nodes, :mongo_id, :text
  end
end
