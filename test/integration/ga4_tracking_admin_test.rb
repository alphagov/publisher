require "integration_test_helper"
require "support/ga4_test_helpers"

class Ga4TrackingAdminTest < JavascriptIntegrationTest
  include Ga4TestHelpers

  setup do
    setup_users
    @edition = FactoryBot.create(:answer_edition, title: "Answer edition")
    @test_strategy.switch!(:ga4_form_tracking, true)
  end

  context "Delete edition page" do
    setup do
      visit confirm_destroy_edition_path(@edition)
      disable_form_submit
    end

    should "add delete edition events to the dataLayer on user activity" do
      click_button "Delete edition"

      event_data = get_event_data

      assert_equal "Save", event_data[0]["action"]
      assert_equal "form_response", event_data[0]["event_name"]
      assert_equal "Delete edition", event_data[0]["section"]
      assert_equal "Answer", event_data[0]["tool_name"]
      assert_equal "edit", event_data[0]["type"]
    end
  end
end
