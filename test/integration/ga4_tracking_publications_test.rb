require "integration_test_helper"
require "support/ga4_test_helpers"

class Ga4TrackingPublicationsTest < JavascriptIntegrationTest
  include Ga4TestHelpers

  setup do
    setup_users
    # @edition = FactoryBot.create(:answer_edition, title: "Answer edition")
    @draft_edition = FactoryBot.create(:edition, :draft, title: "Draft edition", updated_at: 1.day.ago)
    @fact_check_edition = FactoryBot.create(:guide_edition, :fact_check, title: "Fact check edition", updated_at: 2.days.ago)
    @in_review_edition = FactoryBot.create(:help_page_edition, :in_review, title: "In review edition", updated_at: 3.days.ago)
    @ready_edition = FactoryBot.create(:transaction_edition, :ready, title: "Ready edition", updated_at: 4.days.ago)

    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_edit_phase_3b, true)
    test_strategy.switch!(:ga4_form_tracking, true)
  end

  context "Find content page" do
    setup do
      # test_strategy = Flipflop::FeatureSet.current.test!
      # test_strategy.switch!(:design_system_edit_phase_3b, true)
      visit find_content_path
      disable_form_submit
      # execute_script("document.querySelector('#states_filter').style.display='block !important'")
    end

    should "push values to the dataLayer on initial page load (no search term)" do
      # Forces the driver to wait for any async javascript to complete
      page.has_css?("[data-ga4-ecommerce-started='true']")

      # fill_in "Title or slug", with: "Search"

      search_data = get_search_data

      print "===="
      print search_data
      print "===="
    end

    should "push values to the dataLayer when the user enters a search term and submits" do
      fill_in "Title or slug", with: "search"
      # within all(".gem-c-select-with-search")[0] do
      #   # execute_script("document.querySelector('.choices__input').style.display='block'")
      #   find("label").click
      #   # within (".choices__list--dropdown") do
      #   #   choices = find_all(".choices__item--choice")
      #   #   choices[1].click
      #   # end
      #   find("#choices--states_filter-item-choice-2").click
      #   # select "Draft", from: "Status"
      # end

      # select "Test user", from: "Assigned to"
      # select "Answer", from: "Content type"
      click_button "Apply filters"

      event_data = get_event_data
      # search_data = get_search_data

      print "==event_data=="
      print event_data
      print "===="

      # print "==search_data=="
      # print search_data
      # print "===="

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
