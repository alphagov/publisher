require "test_helper"
require "gds_api/test_helpers/publishing_api_v2"

class PublishingAPIUpdaterTest < ActiveSupport::TestCase
  include GdsApi::TestHelpers::PublishingApiV2

  context ".perform(edition_id)" do
    setup do
      @content_id = SecureRandom.uuid
      @artefact = FactoryGirl.create(:artefact, content_id: @content_id)
      @edition = FactoryGirl.create(:edition, panopticon_id: @artefact.id, title: "Some Title")

      WebMock.reset!
      stub_any_publishing_api_put_content
    end

    should "notify the publishing API of the updated document" do
      PublishingAPIUpdater.new.perform(@edition.id)

      assert_publishing_api_put_content(@content_id, request_json_includes(
        "content_id" => @content_id,
        "title" => "Some Title",
      ))
    end
  end
end
