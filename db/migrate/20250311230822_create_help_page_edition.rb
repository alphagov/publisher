class CreateHelpPageEdition < ActiveRecord::Migration[7.1]
  def change
    create_table :help_page_editions do |t|
      t.string :body
      t.timestamps
    end
  end
end
