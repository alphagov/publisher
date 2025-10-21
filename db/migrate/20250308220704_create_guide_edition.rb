class CreateGuideEdition < ActiveRecord::Migration[7.1]
  def change
    create_table :guide_editions do |t|
      t.string :video_url
      t.string :video_summary
      t.boolean :hide_chapter_navigation
      t.timestamps
    end
  end
end
