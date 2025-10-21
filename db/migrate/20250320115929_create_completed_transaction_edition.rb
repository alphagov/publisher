class CreateCompletedTransactionEdition < ActiveRecord::Migration[7.1]
  def change
    create_table :completed_transaction_editions do |t|
      t.string :body
      t.json :presentation_toggles, default: {
        "promotion_choice" =>
          {
            "choice" => "none",
            "url" => "",
          },
      }
      t.timestamps
    end
  end
end
