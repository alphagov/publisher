require "test_helper"
require "gds_api/test_helpers/link_checker_api"

class LinkCheckReportCreatorTest < ActiveSupport::TestCase
  include GdsApi::TestHelpers::LinkCheckerApi
  include Rails.application.routes.url_helpers

  def create_edition(govspeak)
    FactoryBot.create(:place_edition, introduction: govspeak)
  end

  setup do
    @stubbed_api_request = stub_link_checker_api_create_batch(
      uris: ["https://www.gov.uk"],
      id: 1234,
      webhook_uri: link_checker_api_callback_url(host: Plek.find("publisher")),
      webhook_secret_token: Rails.application.credentials.link_checker_api_secret_token,
    )
  end

  context ".call" do
    should "make a request the link checker api when the edition has links" do
      edition = create_edition("This is [link](https://www.gov.uk) text.")

      LinkCheckReportCreator.new(
        edition:,
      ).call

      edition.reload

      assert_requested(@stubbed_api_request)
      assert edition.link_check_reports
      assert 1234, edition.link_check_reports.first.batch_id
    end

    should "not make a request the link checker api when the edition has no links" do
      edition = create_edition("This is had no links.")

      LinkCheckReportCreator.new(
        edition:,
      ).call

      edition.reload

      assert_not_requested(@stubbed_api_request)
      assert edition.link_check_reports.empty?
    end
  end
end
