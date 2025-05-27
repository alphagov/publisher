class CreateTransactionEdition < ActiveRecord::Migration[7.1]
  def change
    create_table :transaction_editions do |t|
      t.string :introduction
      t.string :will_continue_on
      t.string :link
      t.string :more_information
      t.string :need_to_know
      t.string :alternate_methods
      t.string :start_button_text, default: "Start now"
      t.timestamps
    end
  end
end
