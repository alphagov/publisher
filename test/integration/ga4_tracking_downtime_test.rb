require "integration_test_helper"
require "support/ga4_test_helpers"

class Ga4DowntimeTest < JavascriptIntegrationTest
  include Ga4TestHelpers

  setup do
    setup_users
    @edition = FactoryBot.create(:transaction_edition, :published)
    @test_strategy.switch!(:ga4_form_tracking, true)
  end

  context "Add downtime message" do
    setup do
      visit root_path
      click_link "Downtime messages"
      click_link "Add downtime"
    end

    should "push the correct values to the dataLayer when a form error is triggered" do
      click_button "Save"

      assert page.has_css?(".gem-c-error-summary")

      event_data = get_event_data

      assert_equal "error", event_data[0]["action"]
      assert_equal "form_error", event_data[0]["event_name"]
      assert_equal "Edit edition", event_data[0]["type"]
      assert_equal "can't be blank", event_data[0]["text"]
      assert_equal "Message", event_data[0]["section"]
      assert_equal "Transaction", event_data[0]["tool_name"]

      assert_equal "error", event_data[1]["action"]
      assert_equal "form_error", event_data[1]["event_name"]
      assert_equal "Edit edition", event_data[1]["type"]
      assert_equal "format is invalid", event_data[1]["text"]
      assert_equal "Start time", event_data[1]["section"]
      assert_equal "Transaction", event_data[1]["tool_name"]

      assert_equal "error", event_data[2]["action"]
      assert_equal "form_error", event_data[2]["event_name"]
      assert_equal "Edit edition", event_data[2]["type"]
      assert_equal "format is invalid", event_data[2]["text"]
      assert_equal "End time", event_data[2]["section"]
      assert_equal "Transaction", event_data[2]["tool_name"]
    end
  end

  context "Edit downtime message" do
    setup do
      Downtime.create!(artefact_id: @edition.artefact.id, start_time: 1.day.ago, end_time: 1.day.from_now, message: "The message")

      visit root_path
      click_link "Downtime messages"
      click_link "Edit downtime"
    end

    should "push the correct values to the dataLayer when a form error is triggered" do
      within all(".gem-c-date-input")[0] do
        fill_in "Day", with: ""
      end

      within all(".gem-c-date-input")[2] do
        fill_in "Day", with: ""
      end

      click_button "Save"

      assert page.has_css?(".gem-c-error-summary")

      event_data = get_event_data

      assert_equal "error", event_data[0]["action"]
      assert_equal "form_error", event_data[0]["event_name"]
      assert_equal "Edit edition", event_data[0]["type"]
      assert_equal "format is invalid", event_data[0]["text"]
      assert_equal "Start time", event_data[0]["section"]
      assert_equal "Transaction", event_data[0]["tool_name"]

      assert_equal "error", event_data[1]["action"]
      assert_equal "form_error", event_data[1]["event_name"]
      assert_equal "Edit edition", event_data[1]["type"]
      assert_equal "format is invalid", event_data[1]["text"]
      assert_equal "End time", event_data[1]["section"]
      assert_equal "Transaction", event_data[1]["tool_name"]
    end
  end
end
