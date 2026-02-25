require "integration_test_helper"
require "support/ga4_test_helpers"

class Ga4TrackingPublicationsTest < JavascriptIntegrationTest
  include Ga4TestHelpers

  setup do
    setup_users

    @draft_edition = FactoryBot.create(:answer_edition, :draft, title: "Test edition one", assigned_to: @author, updated_at: 1.day.ago)
    @fact_check_edition = FactoryBot.create(:guide_edition, :fact_check, title: "Test edition two", assigned_to: @reviewer, updated_at: 2.days.ago)
    @in_review_edition = FactoryBot.create(:help_page_edition, :in_review, title: "Test edition three", assigned_to: @author, updated_at: 3.days.ago)
    @ready_edition = FactoryBot.create(:transaction_edition, :ready, title: "Other edition one", assigned_to: @reviewer, updated_at: 4.days.ago)

    16.times do
      FactoryBot.create(:local_transaction_edition, :amends_needed, title: "Title", assigned_to: @other, updated_at: 5.days.ago)
    end

    @draft_edition_2 = FactoryBot.create(:answer_edition, :draft, title: "Other edition two", assigned_to: @reviewer, updated_at: 6.days.ago)
    @fact_check_edition_2 = FactoryBot.create(:guide_edition, :fact_check, title: "Other edition three", assigned_to: @reviewer, updated_at: 7.days.ago)
    @in_review_edition_2 = FactoryBot.create(:answer_edition, :in_review, title: "Other edition four", assigned_to: @reviewer, updated_at: 8.days.ago)

    @test_strategy.switch!(:design_system_edit_phase_3b, true)
  end

  context "Find content page" do
    setup do
      visit find_content_path
      @base_url = current_url.chomp(find_content_path)
    end

    should "push 'search_data' values to the dataLayer on initial page load (no search term)" do
      search_data = get_search_data

      assert_equal "view_item_list", search_data["event_name"]
      assert_equal 23, search_data["results"]

      assert_equal 0, search_data["ecommerce"]["items"][0]["index"]
      assert_equal edition_url(@draft_edition, host: @base_url), search_data["ecommerce"]["items"][0]["item_id"]
      assert_equal @draft_edition.id, search_data["ecommerce"]["items"][0]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][0]["item_list_name"]

      assert_equal 1, search_data["ecommerce"]["items"][1]["index"]
      assert_equal edition_url(@fact_check_edition, host: @base_url), search_data["ecommerce"]["items"][1]["item_id"]
      assert_equal @fact_check_edition.id, search_data["ecommerce"]["items"][1]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][1]["item_list_name"]

      assert_equal 2, search_data["ecommerce"]["items"][2]["index"]
      assert_equal edition_url(@in_review_edition, host: @base_url), search_data["ecommerce"]["items"][2]["item_id"]
      assert_equal @in_review_edition.id, search_data["ecommerce"]["items"][2]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][2]["item_list_name"]

      assert_equal 3, search_data["ecommerce"]["items"][3]["index"]
      assert_equal edition_url(@ready_edition, host: @base_url), search_data["ecommerce"]["items"][3]["item_id"]
      assert_equal @ready_edition.id, search_data["ecommerce"]["items"][3]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][3]["item_list_name"]
    end

    should "push 'search_data' values to the dataLayer when the user navigates to the next page of results" do
      within "nav.govuk-pagination" do
        click_link "Next"
      end

      search_data = get_search_data

      assert_equal 20, search_data["ecommerce"]["items"][0]["index"]
      assert_equal edition_url(@draft_edition_2, host: @base_url), search_data["ecommerce"]["items"][0]["item_id"]
      assert_equal @draft_edition_2.id, search_data["ecommerce"]["items"][0]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][0]["item_list_name"]

      assert_equal 21, search_data["ecommerce"]["items"][1]["index"]
      assert_equal edition_url(@fact_check_edition_2, host: @base_url), search_data["ecommerce"]["items"][1]["item_id"]
      assert_equal @fact_check_edition_2.id, search_data["ecommerce"]["items"][1]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][1]["item_list_name"]

      assert_equal 22, search_data["ecommerce"]["items"][2]["index"]
      assert_equal edition_url(@in_review_edition_2, host: @base_url), search_data["ecommerce"]["items"][2]["item_id"]
      assert_equal @in_review_edition_2.id, search_data["ecommerce"]["items"][2]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][2]["item_list_name"]
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

    should "push 'search_data' values to the dataLayer when the user selects a value in the 'Title or slug' filter and submits" do
      fill_in "Title or slug", with: "Test"
      click_button "Apply filters"

      assert page.has_css?("tbody .govuk-table__row", count: 3)

      search_data = get_search_data

      assert_equal "view_item_list", search_data["event_name"]
      assert_equal 3, search_data["results"]

      assert_equal 0, search_data["ecommerce"]["items"][0]["index"]
      assert_equal edition_url(@draft_edition, host: @base_url), search_data["ecommerce"]["items"][0]["item_id"]
      assert_equal @draft_edition.id, search_data["ecommerce"]["items"][0]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][0]["item_list_name"]

      assert_equal 1, search_data["ecommerce"]["items"][1]["index"]
      assert_equal edition_url(@fact_check_edition, host: @base_url), search_data["ecommerce"]["items"][1]["item_id"]
      assert_equal @fact_check_edition.id, search_data["ecommerce"]["items"][1]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][1]["item_list_name"]

      assert_equal 2, search_data["ecommerce"]["items"][2]["index"]
      assert_equal edition_url(@in_review_edition, host: @base_url), search_data["ecommerce"]["items"][2]["item_id"]
      assert_equal @in_review_edition.id, search_data["ecommerce"]["items"][2]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][2]["item_list_name"]
    end

    should "push 'search_data' values to the dataLayer when the user selects a value in the 'Status' filter and submits" do
      # Select Draft
      within all(".gem-c-select-with-search")[0] do
        find("label").click
        find("#choices--states_filter-item-choice-2").click
      end

      click_button "Apply filters"

      search_data = get_search_data

      # Should get @draft_edition and @draft_edition_2
      assert_equal "view_item_list", search_data["event_name"]
      assert_equal 2, search_data["results"]

      assert_equal 0, search_data["ecommerce"]["items"][0]["index"]
      assert_equal edition_url(@draft_edition, host: @base_url), search_data["ecommerce"]["items"][0]["item_id"]
      assert_equal @draft_edition.id, search_data["ecommerce"]["items"][0]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][0]["item_list_name"]

      assert_equal 1, search_data["ecommerce"]["items"][1]["index"]
      assert_equal edition_url(@draft_edition_2, host: @base_url), search_data["ecommerce"]["items"][1]["item_id"]
      assert_equal @draft_edition_2.id, search_data["ecommerce"]["items"][1]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][1]["item_list_name"]
    end

    should "push 'search_data' values to the dataLayer when the user selects a value in the 'Assigned to' filter and submits" do
      # Select Author
      within all(".gem-c-select-with-search")[1] do
        find("label").click
        find("#choices--assignee_filter-item-choice-2").click
      end

      click_button "Apply filters"

      assert page.has_css?("tbody .govuk-table__row", count: 2)

      search_data = get_search_data

      # Should get @draft_edition and @in_review_edition
      assert_equal "view_item_list", search_data["event_name"]
      assert_equal 2, search_data["results"]

      assert_equal 0, search_data["ecommerce"]["items"][0]["index"]
      assert_equal edition_url(@draft_edition, host: @base_url), search_data["ecommerce"]["items"][0]["item_id"]
      assert_equal @draft_edition.id, search_data["ecommerce"]["items"][0]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][0]["item_list_name"]

      assert_equal 1, search_data["ecommerce"]["items"][1]["index"]
      assert_equal edition_url(@in_review_edition, host: @base_url), search_data["ecommerce"]["items"][1]["item_id"]
      assert_equal @in_review_edition.id, search_data["ecommerce"]["items"][1]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][1]["item_list_name"]
    end

    should "push 'search_data' values to the dataLayer when the user selects a value in the 'Content type' filter and submits" do
      # Select Answer
      within all(".gem-c-select-with-search")[2] do
        find("label").click
        find("#choices--content_type_filter-item-choice-2").click
      end

      click_button "Apply filters"

      assert page.has_css?("tbody .govuk-table__row", count: 3)

      search_data = get_search_data

      # Should get @draft_edition, @draft_edition_2, @in_review_edition_2
      assert_equal "view_item_list", search_data["event_name"]
      assert_equal 3, search_data["results"]

      assert_equal 0, search_data["ecommerce"]["items"][0]["index"]
      assert_equal edition_url(@draft_edition, host: @base_url), search_data["ecommerce"]["items"][0]["item_id"]
      assert_equal @draft_edition.id, search_data["ecommerce"]["items"][0]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][0]["item_list_name"]

      assert_equal 1, search_data["ecommerce"]["items"][1]["index"]
      assert_equal edition_url(@draft_edition_2, host: @base_url), search_data["ecommerce"]["items"][1]["item_id"]
      assert_equal @draft_edition_2.id, search_data["ecommerce"]["items"][1]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][1]["item_list_name"]

      assert_equal 2, search_data["ecommerce"]["items"][2]["index"]
      assert_equal edition_url(@in_review_edition_2, host: @base_url), search_data["ecommerce"]["items"][2]["item_id"]
      assert_equal @in_review_edition_2.id, search_data["ecommerce"]["items"][2]["item_content_id"]
      assert_equal "Find content", search_data["ecommerce"]["items"][2]["item_list_name"]
    end

    should "push 'search_data' values to the dataLayer when the user selects the first result" do
      disable_links

      within "tbody" do
        within all(".govuk-table__row")[0] do
          find("a").click
        end
      end

      search_data = get_search_data

      assert_equal "select_item", search_data["event_name"]
      assert_equal 23, search_data["results"]
      assert_equal 0, search_data["ecommerce"]["items"][0]["index"]
      assert_equal edition_url(@draft_edition, host: @base_url), search_data["ecommerce"]["items"][0]["item_id"]
      assert_equal @draft_edition.id, search_data["ecommerce"]["items"][0]["item_content_id"]
      assert_equal "Test edition one", search_data["ecommerce"]["items"][0]["item_name"]
      assert_equal "Find content", search_data["ecommerce"]["items"][0]["item_list_name"]
    end

    should "push 'search_data' values to the dataLayer when the user selects the second result" do
      disable_links

      within "tbody" do
        within all(".govuk-table__row")[1] do
          find("a").click
        end
      end

      search_data = get_search_data

      assert_equal "select_item", search_data["event_name"]
      assert_equal 23, search_data["results"]
      assert_equal 1, search_data["ecommerce"]["items"][0]["index"]
      assert_equal edition_url(@fact_check_edition, host: @base_url), search_data["ecommerce"]["items"][0]["item_id"]
      assert_equal @fact_check_edition.id, search_data["ecommerce"]["items"][0]["item_content_id"]
      assert_equal "Test edition two", search_data["ecommerce"]["items"][0]["item_name"]
      assert_equal "Find content", search_data["ecommerce"]["items"][0]["item_list_name"]
    end

    should "push 'search_data' values to the dataLayer when the user selects the third result" do
      disable_links

      within "tbody" do
        within all(".govuk-table__row")[2] do
          find("a").click
        end
      end

      search_data = get_search_data

      assert_equal "select_item", search_data["event_name"]
      assert_equal 23, search_data["results"]
      assert_equal 2, search_data["ecommerce"]["items"][0]["index"]
      assert_equal edition_url(@in_review_edition, host: @base_url), search_data["ecommerce"]["items"][0]["item_id"]
      assert_equal @in_review_edition.id, search_data["ecommerce"]["items"][0]["item_content_id"]
      assert_equal "Test edition three", search_data["ecommerce"]["items"][0]["item_name"]
      assert_equal "Find content", search_data["ecommerce"]["items"][0]["item_list_name"]
    end

    should "push 'search_data' values to the dataLayer when the user selects the fourth result" do
      disable_links

      within "tbody" do
        within all(".govuk-table__row")[3] do
          find("a").click
        end
      end

      search_data = get_search_data

      assert_equal "select_item", search_data["event_name"]
      assert_equal 23, search_data["results"]
      assert_equal 3, search_data["ecommerce"]["items"][0]["index"]
      assert_equal edition_url(@ready_edition, host: @base_url), search_data["ecommerce"]["items"][0]["item_id"]
      assert_equal @ready_edition.id, search_data["ecommerce"]["items"][0]["item_content_id"]
      assert_equal "Other edition one", search_data["ecommerce"]["items"][0]["item_name"]
      assert_equal "Find content", search_data["ecommerce"]["items"][0]["item_list_name"]
    end

    should "push 'event_data' values to the dataLayer when the user selects 'Clear filters'" do
      fill_in "Title or slug", with: "Title"
      click_button "Apply filters"

      assert page.has_css?("tbody .govuk-table__row", count: 16)

      disable_links

      click_link "Clear filters"

      event_data = get_event_data

      assert_equal "remove", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "false", event_data[0]["external"]
      assert_equal current_host, event_data[0]["link_domain"]
      assert_equal "primary click", event_data[0]["method"]
      assert_equal "Clear filters", event_data[0]["text"]
      assert_equal find_content_path, event_data[0]["url"]
    end
  end

  context "2i queue page" do
    setup do
      visit two_eye_queue_path
      # @base_url = current_url.chomp(two_eye_queue_path)
      # disable_links
    end

    should "push 'search_result' values to the dataLayer on initial page load" do
      assert page.has_css?("tbody .govuk-table__row", count: 2)

      search_data = get_search_data

      puts "++search_data++"
      puts search_data
      puts "++++"

      # assert_equal "view_item_list", search_data["event_name"]
      # assert_equal 2, search_data["results"]

      # assert_equal 0, search_data["ecommerce"]["items"][0]["index"]
      # assert_equal edition_url(@draft_edition, host: @base_url), search_data["ecommerce"]["items"][0]["item_id"]
      # assert_equal @draft_edition.id, search_data["ecommerce"]["items"][0]["item_content_id"]
      # assert_equal "Find content", search_data["ecommerce"]["items"][0]["item_list_name"]
    end

    should "push 'event_data' values to the dataLayer when the user selects 'English' and 'Welsh' tabs" do
      # skip()
      click_link "English"
      click_link "Welsh"

      event_data = get_event_data

      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "tabs", event_data[0]["type"]
      assert_equal "/2i-queue#english", event_data[0]["url"]
      assert_equal "English", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "2", event_data[0]["index"]["index_section_count"]

      assert_equal "select_content", event_data[1]["event_name"]
      assert_equal "tabs", event_data[1]["type"]
      assert_equal "/2i-queue#welsh", event_data[1]["url"]
      assert_equal "Welsh", event_data[1]["text"]
      assert_equal "2", event_data[1]["index"]["index_section"]
      assert_equal "2", event_data[1]["index"]["index_section_count"]
    end

    should "push 'event_data' values to the dataLayer when the user clicks on the links to editions" do
      skip()
      # Get data for links for @in_review_edition & @in_review_edition_2
      within all("tbody .govuk-table__row")[0] do
        find("a").click
      end

      within all("tbody .govuk-table__row")[1] do
        find("a").click
      end

      event_data = get_event_data

      assert_equal "navigation", event_data[0]["event_name"]
      assert_equal "false", event_data[0]["external"]
      assert_equal current_host, event_data[0]["link_domain"]
      assert_equal "Test edition three", event_data[0]["text"]
      assert_equal "link", event_data[0]["type"]
      assert_equal "/editions/#{@in_review_edition.id.to_s}", event_data[0]["url"]

      assert_equal "navigation", event_data[1]["event_name"]
      assert_equal "false", event_data[1]["external"]
      assert_equal current_host, event_data[1]["link_domain"]
      assert_equal "Other edition four", event_data[1]["text"]
      assert_equal "link", event_data[1]["type"]
      assert_equal "/editions/#{@in_review_edition_2.id.to_s}", event_data[1]["url"]
    end
  end
end
