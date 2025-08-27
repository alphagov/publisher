class AddNewFieldsToLocalTransactions < ActiveRecord::Migration[7.1]
  def change
    add_column :local_transaction_editions, :cta_text, :string
    add_column :local_transaction_editions, :before_results, :string
    add_column :local_transaction_editions, :after_results, :string
  end
end
