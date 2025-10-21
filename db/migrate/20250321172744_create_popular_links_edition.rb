class CreatePopularLinksEdition < ActiveRecord::Migration[7.1]
  def change
    create_table :popular_links_editions do |t|
      t.jsonb :link_items
      t.timestamps
    end
  end
end
