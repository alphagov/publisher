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
    stub_browse_pages
  end

  should "create a new CampaignEdition" do
    visit "/publications/#{@artefact.id}"

    assert page.has_content? "Viewing “No campaign, no gain” Edition 1"

    c = CampaignEdition.first
    assert_equal @artefact.id.to_s, c.panopticon_id
  end

  should "allow editing a CampaignEdition" do
    campaign = FactoryGirl.create(:campaign_edition,
                                 :panopticon_id => @artefact.id,
                                 :title => "Singin' in the campaign",
                                 :body => "I'm singin' in the campaign",
                                 :organisation_formatted_name => "Driver & Vehicle\nLicensing\nAgency",
                                 :organisation_crest => "single-identity",
                                 :organisation_url => "/government/organisations/driver-and-vehicle-licensing-agency",
                                 :organisation_brand_colour => "department-for-transport")
    visit "/editions/#{campaign.to_param}"

    assert page.has_content? "Viewing “Singin' in the campaign” Edition 1"

    assert page.has_field?("Title", :with => "Singin' in the campaign")
    assert page.has_field?("Body", :with => "I'm singin' in the campaign")
    assert page.has_field?("Organisation formatted name", :with => "Driver & Vehicle\nLicensing\nAgency")
    assert page.has_field?("Organisation URL", :with => "/government/organisations/driver-and-vehicle-licensing-agency")

    assert page.has_select?('Organisation crest', :selected => 'Single identity')
    assert page.has_select?('Organisation brand colour', :selected => 'department-for-transport')

    fill_in "Body", :with => "I'm dancin' in the campaign"
    fill_in "Organisation formatted name", :with => "Ministry\nof Magic"
    fill_in "Organisation URL", :with => "/government/organisations/ministry-of-magic"

    select "Portcullis", :from => "Organisation crest"
    select "cabinet-office", :from => "Organisation brand colour"

    save_edition

    assert page.has_content? "Campaign edition was successfully updated."

    c = CampaignEdition.find(campaign.id)
    assert_equal "I'm dancin' in the campaign", c.body
    assert_equal "Ministry\r\nof Magic", c.organisation_formatted_name
    assert_equal "/government/organisations/ministry-of-magic", c.organisation_url
    assert_equal "portcullis", c.organisation_crest
    assert_equal "cabinet-office", c.organisation_brand_colour
  end

  should "allow creating a new version of a CampaignEdition" do
    campaign = FactoryGirl.create(:campaign_edition,
                                 :panopticon_id => @artefact.id,
                                 :state => 'published',
                                 :title => "Campaign on your parade",
                                 :body => "Foo",
                                 :organisation_formatted_name => "Driver & Vehicle\nLicensing\nAgency",
                                 :organisation_crest => "single-identity",
                                 :organisation_url => "/government/organisations/driver-and-vehicle-licensing-agency",
                                 :organisation_brand_colour => "department-for-transport")

    visit "/editions/#{campaign.to_param}"

    click_on "Create new edition"

    assert page.has_content? "Viewing “Campaign on your parade” Edition 2"

    assert page.has_field?("Body", :with => "Foo")
    assert page.has_field?("Organisation formatted name", :with => "Driver & Vehicle\nLicensing\nAgency")
    assert page.has_field?("Organisation URL", :with => "/government/organisations/driver-and-vehicle-licensing-agency")
    assert page.has_select?('Organisation crest', :selected => 'Single identity')
    assert page.has_select?('Organisation brand colour', :selected => 'department-for-transport')
  end

  should "manage images for a CampaignEdition" do
    c = FactoryGirl.create(:campaign_edition,
                             :panopticon_id => @artefact.id,
                             :state => 'draft',
                             :title => "Max Campaign",
                             :body => "Foo")

    small_image = File.open(Rails.root.join("test","fixtures","uploads","campaign_small.jpg"))
    medium_image = File.open(Rails.root.join("test","fixtures","uploads","campaign_medium.jpg"))
    large_image = File.open(Rails.root.join("test","fixtures","uploads","campaign_large.jpg"))

    asset_one = OpenStruct.new(:id => 'http://asset-manager.dev.gov.uk/assets/asset_one', :file_url => 'http://path/to/campaign_small.jpg')
    asset_two = OpenStruct.new(:id => 'http://asset-manager.dev.gov.uk/assets/asset_two', :file_url => 'http://path/to/campaign_medium.jpg')
    asset_three = OpenStruct.new(:id => 'http://asset-manager.dev.gov.uk/assets/asset_three', :file_url => 'http://path/to/campaign_large.jpg')

    # This matches against the original_filename attribute on ActionDispatch::Http::UploadedFile
    GdsApi::AssetManager.any_instance.stubs(:create_asset).with(has_entry(:file => responds_with(:original_filename, "campaign_small.jpg"))).returns(asset_one)
    GdsApi::AssetManager.any_instance.stubs(:create_asset).with(has_entry(:file => responds_with(:original_filename, "campaign_medium.jpg"))).returns(asset_two)
    GdsApi::AssetManager.any_instance.stubs(:create_asset).with(has_entry(:file => responds_with(:original_filename, "campaign_large.jpg"))).returns(asset_three)

    GdsApi::AssetManager.any_instance.stubs(:asset).with("asset_one").returns(asset_one)
    GdsApi::AssetManager.any_instance.stubs(:asset).with("asset_two").returns(asset_two)
    GdsApi::AssetManager.any_instance.stubs(:asset).with("asset_three").returns(asset_three)

    visit "/editions/#{c.to_param}"

    within(:css, "#small-campaign-image") do
      assert page.has_field?("Upload image", :type => "file")
      attach_file("Upload image", small_image.path)
    end
    within(:css, "#medium-campaign-image") do
      assert page.has_field?("Upload image", :type => "file")
      attach_file("Upload image", medium_image.path)
    end
    within(:css, "#large-campaign-image") do
      assert page.has_field?("Upload image", :type => "file")
      attach_file("Upload image", large_image.path)
    end

    save_edition

    assert page.has_content?("Campaign edition was successfully updated.")

    assert page.has_selector?("#small-campaign-image a[href$='campaign_small.jpg']")
    assert page.has_selector?("#medium-campaign-image a[href$='campaign_medium.jpg']")
    assert page.has_selector?("#large-campaign-image a[href$='campaign_large.jpg']")

    # ensure files are not removed on save
    save_edition

    assert page.has_selector?("#small-campaign-image a[href$='campaign_small.jpg']")
    assert page.has_selector?("#medium-campaign-image a[href$='campaign_medium.jpg']")
    assert page.has_selector?("#large-campaign-image a[href$='campaign_large.jpg']")

    # remove file
    find('#edition_remove_small_image').trigger('click')
    find('#edition_remove_medium_image').trigger('click')
    find('#edition_remove_large_image').trigger('click')

    save_edition

    refute page.has_selector?("#small-campaign-image a")
    refute page.has_selector?("#medium-campaign-image a")
    refute page.has_selector?("#large-campaign-image a")
  end
end
