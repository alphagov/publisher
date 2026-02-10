require "integration_test_helper"
require "support/ga4_test_helpers"

class Ga4TrackingPublicationsTest < JavascriptIntegrationTest
  include Ga4TestHelpers

  setup do
    setup_users
    # login_as_govuk_editor

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

    should "push 'event_data' values to the dataLayer when the user selects values in the filters and submits" do
      fill_in "Title or slug", with: "search-term"

      within all(".gem-c-select-with-search")[0] do
        find("label").click
        find("#choices--states_filter-item-choice-2").click
      end

      within all(".gem-c-select-with-search")[1] do
        find("label").click
        find("#choices--assignee_filter-item-choice-2").click
      end
 
      within all(".gem-c-select-with-search")[2] do
        find("label").click
        find("#choices--content_type_filter-item-choice-2").click
      end
 
      click_button "Apply filters"

      event_data = get_event_data

      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Status", event_data[0]["section"]
      assert_equal "Draft", event_data[0]["text"]
      assert_equal "2", event_data[0]["index"]["index_section"]
      assert_equal "4", event_data[0]["index"]["index_section_count"]

      assert_equal "select", event_data[1]["action"]
      assert_equal "select_content", event_data[1]["event_name"]
      assert_equal "Assigned to", event_data[1]["section"]
      assert_equal "Author (You)", event_data[1]["text"]
      assert_equal "3", event_data[1]["index"]["index_section"]
      assert_equal "4", event_data[1]["index"]["index_section_count"]

      assert_equal "select", event_data[2]["action"]
      assert_equal "select_content", event_data[2]["event_name"]
      assert_equal "Content type", event_data[2]["section"]
      assert_equal "Answer", event_data[2]["text"]
      assert_equal "4", event_data[2]["index"]["index_section"]
      assert_equal "4", event_data[2]["index"]["index_section_count"]

      assert_equal "search", event_data[3]["action"]
      assert_equal "search", event_data[3]["event_name"]
      assert_equal "index_additions", event_data[3]["type"]
      assert_equal "Find content", event_data[3]["section"]
      assert_equal "search-term", event_data[3]["text"]
      assert_equal "/find-content", event_data[3]["url"]
    end

    should "push values to the dataLayer when the user visits multiple pages of results" do
    end

    should "push values to the dataLayer when the user selects an edition to visit from the list of results" do
    end

    should "push values to the dataLayer when the user selects 'Clear filters'" do
    end
  end
end
