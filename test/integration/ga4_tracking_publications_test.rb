require "integration_test_helper"
require "support/ga4_test_helpers"

class Ga4TrackingPublicationsTest < JavascriptIntegrationTest
  include Ga4TestHelpers

  setup do
    setup_users
    # login_as_govuk_editor

    # @edition = FactoryBot.create(:answer_edition, title: "Answer edition")
    @draft_edition = FactoryBot.create(:answer_edition, :draft, title: "Test edition one", assigned_to: @author, updated_at: 1.day.ago)
    @fact_check_edition = FactoryBot.create(:guide_edition, :fact_check, title: "Test edition two", assigned_to: @reviewer, updated_at: 2.days.ago)
    @in_review_edition = FactoryBot.create(:help_page_edition, :in_review, title: "Test edition three", assigned_to: @author, updated_at: 3.days.ago)
    @ready_edition = FactoryBot.create(:transaction_edition, :ready, title: "Other edition one", assigned_to: @reviewer, updated_at: 4.days.ago)
    @draft_edition_2 = FactoryBot.create(:answer_edition, :draft, title: "Other edition two", assigned_to: @reviewer, updated_at: 5.day.ago)
    @fact_check_edition_2 = FactoryBot.create(:guide_edition, :fact_check, title: "Other edition three", assigned_to: @reviewer, updated_at: 6.days.ago)
    @in_review_edition_2 = FactoryBot.create(:answer_edition, :in_review, title: "Other edition four", assigned_to: @reviewer, updated_at: 7.days.ago)
    # @ready_edition_2 = FactoryBot.create(:answer_edition, :ready, title: "Other edition one", updated_at: 8.days.ago)

    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_edit_phase_3b, true)
    test_strategy.switch!(:ga4_form_tracking, true)
  end

  context "Find content page" do
    setup do
      FilteredEditionsPresenter::ITEMS_PER_PAGE = 4

      # print "==ITEMS_PER_PAGE=="
      # print FilteredEditionsPresenter::ITEMS_PER_PAGE
      # print "===="

      # test_strategy = Flipflop::FeatureSet.current.test!
      # test_strategy.switch!(:design_system_edit_phase_3b, true)
      visit find_content_path
      # disable_form_submit
      # execute_script("document.querySelector('#states_filter').style.display='block !important'")
    end

    # TODO: add pagination test to this one - use full number of items per page elsewhere and restrict it here
    should "push values to the dataLayer on initial page load (no search term)" do
      disable_form_submit

      # Forces the driver to wait for any async javascript to complete
      # page.has_css?('[data-ga4-ecommerce-started="true"]')

      search_data = get_search_data
      # event_data = get_event_data
      base_url = URI.parse(current_url).to_s.chomp(find_content_path) + "/editions/" # + "/editions/" + @draft_edition.id # URI.parse(base_url).to_s

      # print "==search_data=="
      # print search_data
      # print "===="
      # print URI.parse(base_url) # .to_s.chomp(find_content_path) + "/editions/" + @draft_edition.id
      # print "===="

      assert_equal "view_item_list", search_data["event_name"]
      assert_equal 7, search_data["results"]

      assert_equal 0, search_data["ecommerce"]["items"][0]["index"]
      assert_equal base_url + @draft_edition.id, search_data["ecommerce"]["items"][0]["item_id"]
      assert_equal @draft_edition.id, search_data["ecommerce"]["items"][0]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][0]["item_list_name"]

      assert_equal 1, search_data["ecommerce"]["items"][1]["index"]
      assert_equal base_url + @fact_check_edition.id, search_data["ecommerce"]["items"][1]["item_id"]
      assert_equal @fact_check_edition.id, search_data["ecommerce"]["items"][1]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][1]["item_list_name"]

      assert_equal 2, search_data["ecommerce"]["items"][2]["index"]
      assert_equal base_url + @in_review_edition.id, search_data["ecommerce"]["items"][2]["item_id"]
      assert_equal @in_review_edition.id, search_data["ecommerce"]["items"][2]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][2]["item_list_name"]

      assert_equal 3, search_data["ecommerce"]["items"][3]["index"]
      assert_equal base_url + @ready_edition.id, search_data["ecommerce"]["items"][3]["item_id"]
      assert_equal @ready_edition.id, search_data["ecommerce"]["items"][3]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][3]["item_list_name"]
    end

    should "push 'event_data' values to the dataLayer when the user selects values in the filters and submits" do
      disable_form_submit

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

      # print "==event_data=="
      # print event_data
      # print "===="

      # search_data = get_search_data

      # print "==search_data=="
      # print search_data
      # print "===="

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

      # assert_equal "view_item_list", search_data["event_name"]
      # assert_equal 4, search_data["results"]
    end

    # TODO: break this into one filter at a time
    should "push 'search_data' values to the dataLayer when the user selects a value in the 'Title or slug' filter and submits" do
      fill_in "Title or slug", with: "Test"

      # within all(".gem-c-select-with-search")[0] do
      #   find("label").click
      #   find("#choices--states_filter-item-choice-2").click
      # end

      # within all(".gem-c-select-with-search")[1] do
      #   find("label").click
      #   find("#choices--assignee_filter-item-choice-2").click
      # end
 
      # within all(".gem-c-select-with-search")[2] do
      #   find("label").click
      #   find("#choices--content_type_filter-item-choice-2").click
      # end
 
      click_button "Apply filters"

      search_data = get_search_data
      base_url = URI.parse(current_url).to_s.chomp(find_content_path) + "/editions/"

      print "==search_data=="
      print search_data
      print "===="

      assert_equal "view_item_list", search_data["event_name"]
      assert_equal 3, search_data["results"]

      assert_equal 0, search_data["ecommerce"]["items"][0]["index"]
      assert_equal base_url + @draft_edition.id, search_data["ecommerce"]["items"][0]["item_id"]
      assert_equal @draft_edition.id, search_data["ecommerce"]["items"][0]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][0]["item_list_name"]

      assert_equal 1, search_data["ecommerce"]["items"][1]["index"]
      assert_equal base_url + @fact_check_edition.id, search_data["ecommerce"]["items"][1]["item_id"]
      assert_equal @fact_check_edition.id, search_data["ecommerce"]["items"][1]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][1]["item_list_name"]

      assert_equal 2, search_data["ecommerce"]["items"][2]["index"]
      assert_equal base_url + @in_review_edition.id, search_data["ecommerce"]["items"][2]["item_id"]
      assert_equal @in_review_edition.id, search_data["ecommerce"]["items"][2]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][2]["item_list_name"]
    end

    should "push 'search_data' values to the dataLayer when the user selects a value in the 'Status' filter and submits" do
      # fill_in "Title or slug", with: "Test"

      # Select Draft
      within all(".gem-c-select-with-search")[0] do
        find("label").click
        find("#choices--states_filter-item-choice-2").click
      end

      # within all(".gem-c-select-with-search")[1] do
      #   find("label").click
      #   find("#choices--assignee_filter-item-choice-2").click
      # end

      # within all(".gem-c-select-with-search")[2] do
      #   find("label").click
      #   find("#choices--content_type_filter-item-choice-2").click
      # end

      click_button "Apply filters"

      search_data = get_search_data
      base_url = URI.parse(current_url).to_s.chomp(find_content_path) + "/editions/"

      print "==search_data=="
      print search_data
      print "===="

      # Should get @draft_edition and @draft_edition_2
      assert_equal "view_item_list", search_data["event_name"]
      assert_equal 2, search_data["results"]

      assert_equal 0, search_data["ecommerce"]["items"][0]["index"]
      assert_equal base_url + @draft_edition.id, search_data["ecommerce"]["items"][0]["item_id"]
      assert_equal @draft_edition.id, search_data["ecommerce"]["items"][0]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][0]["item_list_name"]

      assert_equal 1, search_data["ecommerce"]["items"][1]["index"]
      assert_equal base_url + @draft_edition_2.id, search_data["ecommerce"]["items"][1]["item_id"]
      assert_equal @draft_edition_2.id, search_data["ecommerce"]["items"][1]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][1]["item_list_name"]
    end

    should "push 'search_data' values to the dataLayer when the user selects a value in the 'Assigned to' filter and submits" do
      # fill_in "Title or slug", with: "Test"

      # Select Draft
      # within all(".gem-c-select-with-search")[0] do
      #   find("label").click
      #   find("#choices--states_filter-item-choice-2").click
      # end

      # Select Author
      within all(".gem-c-select-with-search")[1] do
        find("label").click
        find("#choices--assignee_filter-item-choice-2").click
      end

      # within all(".gem-c-select-with-search")[2] do
      #   find("label").click
      #   find("#choices--content_type_filter-item-choice-2").click
      # end

      click_button "Apply filters"

      search_data = get_search_data
      base_url = URI.parse(current_url).to_s.chomp(find_content_path) + "/editions/"

      print "==search_data=="
      print search_data
      print "===="

      # Should get @draft_edition and @in_review_edition
      assert_equal "view_item_list", search_data["event_name"]
      assert_equal 2, search_data["results"]

      assert_equal 0, search_data["ecommerce"]["items"][0]["index"]
      assert_equal base_url + @draft_edition.id, search_data["ecommerce"]["items"][0]["item_id"]
      assert_equal @draft_edition.id, search_data["ecommerce"]["items"][0]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][0]["item_list_name"]

      assert_equal 1, search_data["ecommerce"]["items"][1]["index"]
      assert_equal base_url + @in_review_edition.id, search_data["ecommerce"]["items"][1]["item_id"]
      assert_equal @in_review_edition.id, search_data["ecommerce"]["items"][1]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][1]["item_list_name"]
    end

    should "push 'search_data' values to the dataLayer when the user selects a value in the 'Content type' filter and submits" do
      # fill_in "Title or slug", with: "Test"

      # Select Draft
      # within all(".gem-c-select-with-search")[0] do
      #   find("label").click
      #   find("#choices--states_filter-item-choice-2").click
      # end

      # Select Author
      # within all(".gem-c-select-with-search")[1] do
      #   find("label").click
      #   find("#choices--assignee_filter-item-choice-2").click
      # end

      # Select Answer
      within all(".gem-c-select-with-search")[2] do
        find("label").click
        find("#choices--content_type_filter-item-choice-2").click
      end

      click_button "Apply filters"

      search_data = get_search_data
      base_url = URI.parse(current_url).to_s.chomp(find_content_path) + "/editions/"

      print "==search_data=="
      print search_data
      print "===="

      # Should get @draft_edition, @draft_edition_2, @in_review_edition_2
      assert_equal "view_item_list", search_data["event_name"]
      assert_equal 3, search_data["results"]

      assert_equal 0, search_data["ecommerce"]["items"][0]["index"]
      assert_equal base_url + @draft_edition.id, search_data["ecommerce"]["items"][0]["item_id"]
      assert_equal @draft_edition.id, search_data["ecommerce"]["items"][0]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][0]["item_list_name"]

      assert_equal 1, search_data["ecommerce"]["items"][1]["index"]
      assert_equal base_url + @draft_edition_2.id, search_data["ecommerce"]["items"][1]["item_id"]
      assert_equal @draft_edition_2.id, search_data["ecommerce"]["items"][1]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][1]["item_list_name"]

      assert_equal 2, search_data["ecommerce"]["items"][2]["index"]
      assert_equal base_url + @in_review_edition_2.id, search_data["ecommerce"]["items"][2]["item_id"]
      assert_equal @in_review_edition_2.id, search_data["ecommerce"]["items"][2]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][2]["item_list_name"]
    end

    should "push values to the dataLayer when the user visits multiple pages of results (via pagination)" do
    end

    should "push values to the dataLayer when the user selects an edition to visit from the list of results" do
      disable_links

      # print "==h1=="
      # print find("h1").text
      # print "===="

      within "tbody" do
        within all(".govuk-table__row")[0] do
          # print "===="
          # print "first row"
          # print find("a").text
          # print "===="

          find("a").click

          print "==current_path=="
          print current_path
          print "===="

          # event_data = get_event_data

          # print "===="
          # print event_data
          # print "===="
        end

        # within all(".govuk-table__row")[1] do
        #   print "===="
        #   # print "second row"
        #   print find('a').text
        #   print "===="
        # end

        # within all(".govuk-table__row")[2] do
        #   print "===="
        #   # print "third row"
        #   print find('a').text
        #   print "===="
        # end

        # within all(".govuk-table__row")[3] do
        #   print "===="
        #   # print "fourth row"
        #   print find('a').text
        #   print "===="
        # end
      end

      event_data = get_event_data

      print "===="
      print event_data
      print "===="

      assert page.has_css?("h1", text: "Find content")
    end

    should "push values to the dataLayer when the user selects 'Clear filters'" do
    end
  end
end
