require "integration_test_helper"
require "support/ga4_test_helpers"

class Ga4TrackingAddArtefactTest < JavascriptIntegrationTest
  include Ga4TestHelpers

  setup do
    setup_users

    @test_strategy.switch!(:ga4_form_tracking, true)
  end

  context "Create new content page one" do
    should "push the correct values to the dataLayer when a form error is triggered" do
      visit new_artefact_path

      click_button "Continue"

      assert page.has_css?("h1", text: "Create new content")

      event_data = get_event_data

      assert_equal "error", event_data[0]["action"]
      assert_equal "form_error", event_data[0]["event_name"]
      assert_equal "Edit edition", event_data[0]["type"]
      assert_equal "Select a content type", event_data[0]["text"]
      assert_equal "Kind", event_data[0]["section"]
      assert_equal "Publisher", event_data[0]["tool_name"]
    end

    should "push the correct values to the dataLayer when user without 'govuk_editor' permissions tries to visit 'Create new content' page" do
      login_as(@user_no_permissions)

      visit new_artefact_path

      assert page.has_css?("h1", text: "My content")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "You do not have permission to see this page.", event_data[0]["text"]
    end

    should "push the correct values to the dataLayer when user without 'govuk_editor' permissions tries to continue from 'Create new content' page" do
      visit new_artefact_path

      login_as(@user_no_permissions)

      click_button "Continue"

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "You do not have permission to see this page.", event_data[0]["text"]
    end
  end

  context "Create new content page two" do
    setup do
      FactoryBot.create(:local_service, lgsl_code: 1)
 
      visit new_artefact_path
      find("label", text: "Local transaction").click
      click_button "Continue"
    end

    should "push the correct values to the dataLayer when a form error is triggered" do
      click_button "Create content"

      assert page.has_css?(".gem-c-heading__context", text: "Create new content")

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

    should "push the correct values to the dataLayer when user without 'govuk_editor' permissions tries to fill in form and submit" do
      login_as(@user_no_permissions)

      fill_in "Title", with: "The title"
      fill_in "Slug", with: "the-title"

      click_button "Create content"

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "You do not have permission to see this page.", event_data[0]["text"]
    end
  end
end
