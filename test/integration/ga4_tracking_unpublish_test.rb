require "integration_test_helper"
require "support/ga4_test_helpers"

class Ga4TrackingUnpublishTest < JavascriptIntegrationTest
  include Ga4TestHelpers

  setup do
    setup_users
    @edition = FactoryBot.create(:answer_edition, state: "published", title: "Answer edition")
    @test_strategy.switch!(:ga4_form_tracking, true)
  end

  context "Unpublish tab" do
    setup do
      visit unpublish_edition_path(@edition)
    end

    should "add unpublish events to the dataLayer" do
      disable_form_submit

      fill_in "Redirect to URL", with: "https://www.gov.uk/redirect"
      click_button "Continue"

      event_data = get_event_data

      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Redirect to URL", event_data[0]["section"]
      assert_equal "27", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "1", event_data[0]["index"]["index_section_count"]

      assert_equal "Save", event_data[1]["action"]
      assert_equal "form_response", event_data[1]["event_name"]
      assert_equal "Unpublish", event_data[1]["section"]
      assert_equal "{\"Redirect to URL\":\"27\"}", event_data[1]["text"]
      assert_equal "Answer", event_data[1]["tool_name"]
      assert_equal "edit", event_data[1]["type"]
    end

    should "push the correct values to the dataLayer when a form error is triggered" do
      stub_linkables_with_data
      fill_in "Redirect to URL", with: "an-invalid-value"
      click_button "Continue"

      assert page.has_css?("h2", text: "Unpublish")

      event_data = get_event_data

      assert_equal "error", event_data[0]["action"]
      assert_equal "form_error", event_data[0]["event_name"]
      assert_equal "Edit edition", event_data[0]["type"]
      assert_equal "Redirect path is invalid. Answer can not be unpublished.", event_data[0]["text"]
      assert_equal "Redirect URL", event_data[0]["section"]
      assert_equal "Answer", event_data[0]["tool_name"]
    end
  end
end
