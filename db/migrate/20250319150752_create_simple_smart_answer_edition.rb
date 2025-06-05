class CreateSimpleSmartAnswerEdition < ActiveRecord::Migration[7.1]
  def change
    create_table :simple_smart_answer_editions do |t|
      t.string :body
      t.string :start_button_text, default: "Start now"
      t.timestamps
    end
  end
end
