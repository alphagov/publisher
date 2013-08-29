#encoding: utf-8
require 'integration_test_helper'

class CampaignEditTest < JavascriptIntegrationTest
  setup do
    @artefact = FactoryGirl.create(:artefact,
        slug: "no-campaign-no-gain",
        kind: "campaign",
        name: "No campaign, no gain",
        owning_app: "publisher",
    )

    setup_users
  end

  should "create a new CampaignEdition" do
    visit "/admin/publications/#{@artefact.id}"

    assert page.has_content? "Viewing “No campaign, no gain” Edition 1"

    c = CampaignEdition.first
    assert_equal @artefact.id.to_s, c.panopticon_id
  end

  should "allow editing a CampaignEdition" do
    campaign = FactoryGirl.create(:campaign_edition,
                                 :panopticon_id => @artefact.id,
                                 :title => "Singin' in the campaign",
                                 :body => "I'm singin' in the campaign")
    visit "/admin/editions/#{campaign.to_param}"

    assert page.has_content? "Viewing “Singin' in the campaign” Edition 1"

    assert page.has_field?("Title", :with => "Singin' in the campaign")
    assert page.has_field?("Body", :with => "I'm singin' in the campaign")

    fill_in "Body", :with => "I'm dancin' in the campaign"

    click_button "Save"

    assert page.has_content? "Campaign edition was successfully updated."

    c = CampaignEdition.find(campaign.id)
    assert_equal "I'm dancin' in the campaign", c.body
  end

  should "allow creating a new version of a CampaignEdition" do
    campaign = FactoryGirl.create(:campaign_edition,
                                 :panopticon_id => @artefact.id,
                                 :state => 'published',
                                 :title => "Campaign on your parade",
                                 :body => "Foo")

    visit "/admin/editions/#{campaign.to_param}"

    click_on "Create new edition"

    assert page.has_content? "Viewing “Campaign on your parade” Edition 2"

    assert page.has_field?("Body", :with => "Foo")
  end
end
