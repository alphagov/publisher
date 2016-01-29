require "test_helper"
require "gds_api/test_helpers/publishing_api_v2"

class PublishingAPIUpdateNotifierTest < ActiveSupport::TestCase
  include GdsApi::TestHelpers::PublishingApiV2

  context ".perform(edition_id)" do
    setup do
      Edition.after_save.clear #avoids automated calls to PublishingAPIUpdateNotifier

      @edition = FactoryGirl.create(:edition)
      @edition_attributes = {
        content_id: "vat-charities-id",
        details: {},
        tags: {}
      }

      presenter = mock("published_edition_presenter", render_for_publishing_api: @edition_attributes)
      PublishedEditionPresenter.stubs(:new).with(@edition).returns(presenter)
      stub_publishing_api_put_content("vat-charities-id", @edition_attributes)
    end

    should "notify the publishing API of the updated document" do
      PublishingAPIUpdateNotifier.new.perform(@edition.id)
      assert_publishing_api_put_content("vat-charities-id", @edition_attributes)
    end
  end
end
