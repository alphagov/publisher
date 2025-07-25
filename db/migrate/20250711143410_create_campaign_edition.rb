class CreateCampaignEdition < ActiveRecord::Migration[7.1]
  def change
    create_table :campaign_editions do |t|
      t.string :body
      t.string :organisation_formatted_name
      t.string :organisation_url
      t.string :organisation_brand_colour
      t.string :organisation_crest
      t.timestamps
    end
  end
end
