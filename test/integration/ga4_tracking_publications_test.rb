require "integration_test_helper"
require "support/ga4_test_helpers"

class Ga4TrackingPublicationsTest < JavascriptIntegrationTest
  include Ga4TestHelpers

  setup do
    setup_users
    @edition = FactoryBot.create(:answer_edition, title: "Answer edition")

    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:ga4_form_tracking, true)
    test_strategy.switch!(:design_system_edit_phase_3b, true)
  end

  context "Find content page" do
    setup do
      visit find_content_path
      disable_form_submit
    end

    should "add find content selection events to the dataLayer" do
      fill_in "Title or slug", with: "Search"
      within all(".gem-c-select-with-search")[0] do
        find("label").click
        # within (".choices__list--dropdown") do
        #   choices = find_all(".choices__item--choice")
        #   choices[1].click
        # end
        find("#choices--states_filter-item-choice-2").click
      end

      # select "Test user", from: "Assigned to"
      # select "Answer", from: "Content type"
      # click_button "Apply filters"

      event_data = get_event_data

      print "==== event_data = " + event_data.to_s + "===="

      # assert_equal "select", event_data[0]["action"]
      # assert_equal "select_content", event_data[0]["event_name"]
      # assert_equal "Edition note", event_data[0]["section"]
      # assert_equal "26", event_data[0]["text"]
      # assert_equal "1", event_data[0]["index"]["index_section"]
      # assert_equal "1", event_data[0]["index"]["index_section_count"]

      # assert_equal "Save", event_data[1]["action"]
      # assert_equal "form_response", event_data[1]["event_name"]
      # assert_equal "Add edition note", event_data[1]["section"]
      # assert_equal "{\"Edition note\":\"26\"}", event_data[1]["text"]
      # assert_equal "Answer", event_data[1]["tool_name"]
      # assert_equal "edit", event_data[1]["type"]
    end
  end
end
