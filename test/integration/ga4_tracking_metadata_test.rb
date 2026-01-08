require "integration_test_helper"
require "support/ga4_test_helpers"

class Ga4TrackingMetadataTest < JavascriptIntegrationTest
  include Ga4TestHelpers

  setup do
    FactoryBot.create(:user, :govuk_editor, name: "Test User")
    @govuk_requester = FactoryBot.create(:user, :govuk_editor, :skip_review)
    @edition = FactoryBot.create(:answer_edition, title: "Answer edition")

    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:ga4_form_tracking, true)
  end

  context "Metadata tab" do
    setup do
      visit metadata_edition_path(@edition)
      disable_form_submit
    end

    should "add metadata selection events to the dataLayer" do
      # Fill in the slug field
      fill_in "Slug", with: "ga4-tracking"
      # Select a Language option
      find("label", text: "Welsh").click
      # Select a different Language option
      find("label", text: "English").click
      # Save selections
      click_button "Update"

      event_data = get_event_data

      # "ga4-tracking" entered in the "Slug" field
      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Slug", event_data[0]["section"]
      assert_equal "12", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "2", event_data[0]["index"]["index_section_count"]

      # "Welsh" selected from the "Language" field
      assert_equal "select", event_data[1]["action"]
      assert_equal "select_content", event_data[1]["event_name"]
      assert_equal "Language", event_data[1]["section"]
      assert_equal "Welsh", event_data[1]["text"]
      assert_equal "2", event_data[1]["index"]["index_section"]
      assert_equal "2", event_data[1]["index"]["index_section_count"]

      # "English" selected from the "Language" field
      assert_equal "select", event_data[2]["action"]
      assert_equal "select_content", event_data[2]["event_name"]
      assert_equal "Language", event_data[2]["section"]
      assert_equal "English", event_data[2]["text"]
      assert_equal "2", event_data[2]["index"]["index_section"]
      assert_equal "2", event_data[2]["index"]["index_section_count"]

      # Form submitted with "Slug" field filled in and "English" selected from the Language field
      assert_equal "Save", event_data[3]["action"]
      assert_equal "form_response", event_data[3]["event_name"]
      assert_equal "Answer edition", event_data[3]["section"]
      assert_equal "{\"Slug\":\"12\",\"Language\":\"English\"}", event_data[3]["text"]
      assert_equal "Answer", event_data[3]["tool_name"]
      assert_equal "edit", event_data[3]["type"]
    end
  end
end
