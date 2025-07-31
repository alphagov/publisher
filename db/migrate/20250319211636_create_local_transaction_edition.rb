class CreateLocalTransactionEdition < ActiveRecord::Migration[7.1]
  def change
    create_table :local_transaction_editions do |t|
      t.integer :lgsl_code, type: Integer
      t.integer :lgil_override, type: Integer
      t.integer :lgil_code, type: Integer
      t.string :introduction, type: String
      t.string :more_information, type: String
      t.string :need_to_know, type: String
      t.timestamps
    end
  end
end
