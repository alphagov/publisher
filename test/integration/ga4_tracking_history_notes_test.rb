require "integration_test_helper"
require "support/ga4_test_helpers"

class Ga4TrackingHistoryNotesTest < JavascriptIntegrationTest
  include Ga4TestHelpers

  setup do
    setup_users
    @edition = FactoryBot.create(:answer_edition, title: "Answer edition")

    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:ga4_form_tracking, true)
  end

  context "Add edition note page" do
    setup do
      visit history_add_edition_note_edition_path(@edition)
      disable_form_submit
    end

    should "add edition note selection events to the dataLayer" do
      fill_in "Edition note", with: "This is a new edition note"
      click_button "Save"

      event_data = get_event_data

      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Edition note", event_data[0]["section"]
      assert_equal "26", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "1", event_data[0]["index"]["index_section_count"]

      assert_equal "Save", event_data[1]["action"]
      assert_equal "form_response", event_data[1]["event_name"]
      assert_equal "Add edition note", event_data[1]["section"]
      assert_equal "{\"Edition note\":\"26\"}", event_data[1]["text"]
      assert_equal "Answer", event_data[1]["tool_name"]
      assert_equal "edit", event_data[1]["type"]
    end
  end
end
