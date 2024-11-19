require "legacy_integration_test_helper"
require "gds_api/test_helpers/link_checker_api"

class EditionLinkCheckTest < LegacyJavascriptIntegrationTest
  include GdsApi::TestHelpers::LinkCheckerApi

  setup do
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check

    @stubbed_api_request = stub_link_checker_api_create_batch(
      uris: ["https://www.gov.uk"],
      id: 1234,
      webhook_uri: link_checker_api_callback_url(host: Plek.find("publisher")),
      webhook_secret_token: ENV.fetch("LINK_CHECKER_API_SECRET_TOKEN"),
    )

    @place = FactoryBot.create(:place_edition, introduction: "This is [link](https://www.gov.uk) text.")
  end

  with_and_without_javascript do
    should "create a link check report" do
      visit_edition @place

      within(".broken-links-report") do
        click_on "Check for broken links"
        page.has_content?("Broken link report in progress.")
      end

      assert_requested(@stubbed_api_request)

      @place.reload

      @place.latest_link_check_report.update!(status: "completed")

      within(".broken-links-report") do
        click_on "Refresh"
        page.has_content?("This edition contains no broken links")
      end
    end
  end
end
