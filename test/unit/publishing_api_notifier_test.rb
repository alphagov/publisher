require "test_helper"
require "gds_api/test_helpers/publishing_api"

class PublishingAPINotifierTest < ActiveSupport::TestCase
  include GdsApi::TestHelpers::PublishingApi

  context ".perform(edition_id)" do
    setup do
      @edition = FactoryGirl.create(:edition)

      @edition_attributes = {
        base_path: "/vat-charities",
        details: {},
        tags: {}
      }

      presenter = mock("published_edition_presenter", render_for_publishing_api: @edition_attributes)

      PublishedEditionPresenter.stubs(:new).with(@edition).returns(presenter)
      stub_publishing_api_put_item("/vat-charities", @edition_attributes)
    end

    should "notify the publishing API of the published document" do
      PublishingAPINotifier.new.perform(@edition.id)
      assert_publishing_api_put_item("/vat-charities", @edition_attributes)
    end
  end
end
