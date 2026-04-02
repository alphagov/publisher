require "integration_test_helper"
require "support/ga4_test_helpers"

class Ga4TrackingAddArtefactTest < JavascriptIntegrationTest
  include Ga4TestHelpers

  setup do
    setup_users

    @test_strategy.switch!(:design_system_edit_phase_3b, true)
    @test_strategy.switch!(:design_system_edit_phase_4, true)
    @test_strategy.switch!(:ga4_form_tracking, true)
  end

  context "Create new content page" do
    setup do
      visit new_artefact_path
    end

    should "push the correct values to the dataLayer when a form error is triggered" do
      click_button "Continue"

      event_data = get_event_data

      assert_equal "error", event_data[0]["action"]
      assert_equal "form_error", event_data[0]["event_name"]
      assert_equal "Edit edition", event_data[0]["type"]
      assert_equal "Select a content type", event_data[0]["text"]
      assert_equal "Kind", event_data[0]["section"]
      assert_equal "Publisher", event_data[0]["tool_name"]
    end
  end
end
