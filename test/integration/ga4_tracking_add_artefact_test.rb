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

  context "Create new content page one" do
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

  context "Create new content page two" do
    setup do
      visit new_artefact_path
      choose "Local transaction"
      click_button "Continue"
    end

    should "push the correct values to the dataLayer when a form error is triggered" do
      click_button "Create content"

      event_data = get_event_data

      assert_equal "error", event_data[0]["action"]
      assert_equal "form_error", event_data[0]["event_name"]
      assert_equal "Edit edition", event_data[0]["type"]
      assert_equal "Enter a title", event_data[0]["text"]
      assert_equal "Name", event_data[0]["section"]
      assert_equal "Publisher", event_data[0]["tool_name"]

      assert_equal "error", event_data[1]["action"]
      assert_equal "form_error", event_data[1]["event_name"]
      assert_equal "Edit edition", event_data[1]["type"]
      assert_equal "Enter a slug", event_data[1]["text"]
      assert_equal "Slug", event_data[1]["section"]
      assert_equal "Publisher", event_data[1]["tool_name"]

      assert_equal "error", event_data[2]["action"]
      assert_equal "form_error", event_data[2]["event_name"]
      assert_equal "Edit edition", event_data[2]["type"]
      assert_equal "Enter a LGSL code", event_data[2]["text"]
      assert_equal "Lgsl code", event_data[2]["section"]
      assert_equal "Publisher", event_data[2]["tool_name"]

      assert_equal "error", event_data[3]["action"]
      assert_equal "form_error", event_data[3]["event_name"]
      assert_equal "Edit edition", event_data[3]["type"]
      assert_equal "Enter a LGIL code", event_data[3]["text"]
      assert_equal "Lgil code", event_data[3]["section"]
      assert_equal "Publisher", event_data[3]["tool_name"]
    end
  end
end
