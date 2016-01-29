require "test_helper"
require "gds_api/test_helpers/publishing_api_v2"

class PublishingApiPublisherTest < ActiveSupport::TestCase
  include GdsApi::TestHelpers::PublishingApiV2

  context ".perform(edition_id)" do
    setup do
      @edition = FactoryGirl.create(:edition)

      @edition_attributes = {
        content_id: "vat-charities-id",
        details: {},
        tags: {}
      }

      presenter = mock("published_edition_presenter", render_for_publishing_api: @edition_attributes)

      PublishedEditionPresenter.stubs(:new).with(@edition).returns(presenter)
      stub_publishing_api_put_content("vat-charities-id", @edition_attributes)
      stub_publishing_api_publish("vat-charities-id", {"update_type" => "minor"})
    end

    should "notify the publishing API of the published document" do
      PublishingApiPublisher.new.perform(@edition.id)
      assert_publishing_api_publish("vat-charities-id", {"update_type" => "minor"})
    end
  end
end
