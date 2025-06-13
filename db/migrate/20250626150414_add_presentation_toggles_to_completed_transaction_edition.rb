class AddPresentationTogglesToCompletedTransactionEdition < ActiveRecord::Migration[7.1]
  def change
    add_column :completed_transaction_editions, :presentation_toggles, :json, default: {
      "promotion_choice" =>
        {
          "choice" => "none",
          "url" => "",
        },
    }
  end
end
