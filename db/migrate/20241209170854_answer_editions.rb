class AnswerEditions < ActiveRecord::Migration[7.1]
  def change
    create_table :answer_editions do |t|
      t.string :body
    end
  end
end
