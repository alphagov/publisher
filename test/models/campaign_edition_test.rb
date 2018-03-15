require "test_helper"

class CampaignEditionTest < ActiveSupport::TestCase
  setup do
    @artefact = FactoryBot.create(:artefact, kind: 'campaign', slug: "start-all-the-campaigns")
  end

  should "have correct extra fields" do
    c = FactoryBot.create(
      :campaign_edition,
      panopticon_id: @artefact.id,
      body: "Start all the campaigns!",
      large_image_id: "large-image-id-from-the-asset-manager",
      medium_image_id: "medium-image-id-from-the-asset-manager",
      small_image_id: "small-image-id-from-the-asset-manager",
      organisation_formatted_name: "Driver & Vehicle\nLicensing\nAgency",
      organisation_url: "/government/organisations/driver-and-vehicle-licensing-agency",
      organisation_brand_colour: "department-for-transport",
      organisation_crest: "single-identity",
    )

    assert_equal "Start all the campaigns!", c.body
    assert_equal "large-image-id-from-the-asset-manager", c.large_image_id
    assert_equal "medium-image-id-from-the-asset-manager", c.medium_image_id
    assert_equal "small-image-id-from-the-asset-manager", c.small_image_id
    assert_equal "Driver & Vehicle\nLicensing\nAgency", c.organisation_formatted_name
    assert_equal "/government/organisations/driver-and-vehicle-licensing-agency", c.organisation_url
    assert_equal "department-for-transport", c.organisation_brand_colour
    assert_equal "single-identity", c.organisation_crest
  end

  should "give a friendly (legacy supporting) description of its format" do
    campaign = CampaignEdition.new
    assert_equal "Campaign", campaign.format
  end

  should "return the body as whole_body" do
    campaign = FactoryBot.build(:campaign_edition,
                          panopticon_id: @artefact.id,
                          body: "Something")
    assert_equal campaign.body, campaign.whole_body
  end

  should "be not valid with an organisation brand colour from outside the list" do
    campaign = FactoryBot.build(:campaign_edition, panopticon_id: @artefact.id)
    campaign.organisation_brand_colour = "something-else"

    refute campaign.valid?
    assert campaign.errors.has_key?(:organisation_brand_colour)
  end

  should "be not valid with an organisation crest from outside the list" do
    campaign = FactoryBot.build(:campaign_edition, panopticon_id: @artefact.id)
    campaign.organisation_crest = "something-else"

    refute campaign.valid?
    assert campaign.errors.has_key?(:organisation_crest)
  end

  should "be valid with a blank organisation crest and brand colour" do
    campaign = FactoryBot.build(:campaign_edition, panopticon_id: @artefact.id)
    campaign.organisation_crest = ''
    campaign.organisation_brand_colour = ''

    assert campaign.valid?
  end
end
