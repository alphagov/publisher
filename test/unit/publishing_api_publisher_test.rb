require "test_helper"
require "gds_api/test_helpers/publishing_api_v2"

class PublishingAPIPublisherTest < ActiveSupport::TestCase
  include GdsApi::TestHelpers::PublishingApiV2

  context ".perform(edition_id)" do
    setup do
      @edition = FactoryGirl.create(:edition)
      @artefact = @edition.artefact
      @artefact.update_attributes(content_id: "vat-charities-id")
    end

    should "publish content with the update_type set to nil" do
      stub_publishing_api_publish("vat-charities-id", "update_type" => nil, "locale" => "en")
      PublishingAPIPublisher.new.perform(@edition.id)

      assert_publishing_api_publish("vat-charities-id", "update_type" => nil, "locale" => "en")
    end

    should "publish content with a specified update_type" do
      stub_publishing_api_publish("vat-charities-id", "update_type" => "republish", "locale" => "en")
      PublishingAPIPublisher.new.perform(@edition.id, "republish")

      assert_publishing_api_publish("vat-charities-id", "update_type" => "republish", "locale" => "en")
    end
  end
end
