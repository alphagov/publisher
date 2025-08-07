class CreateLink < ActiveRecord::Migration[7.1]
  def change
    create_table :links do |t|
      t.text :mongo_id
      t.string :uri
      t.string :status
      t.datetime :checked_at
      t.text :check_warnings, array: true, default: []
      t.text :check_errors, array: true, default: []
      t.string :problem_summary
      t.string :suggested_fix

      t.references :link_check_report, foreign_key: true
      t.timestamps
    end
  end
end
