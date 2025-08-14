class CreateVideoEdition < ActiveRecord::Migration[7.1]
  def change
    create_table :video_editions do |t|
      t.string :video_url
      t.string :video_summary
      t.string :body
      t.timestamps
    end
  end
end
