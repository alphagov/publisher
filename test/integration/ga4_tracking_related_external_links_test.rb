require "integration_test_helper"
require "support/ga4_test_helpers"

class Ga4TrackingRelatedExternalLinksTest < JavascriptIntegrationTest
  include Ga4TestHelpers

  setup do
    setup_users
    @edition = FactoryBot.create(:answer_edition, title: "Answer edition")
    @test_strategy.switch!(:ga4_form_tracking, true)
  end

  context "Related external links page" do
    setup do
      visit related_external_links_edition_path(@edition)
      disable_form_submit
    end

    should "add related external links events to the dataLayer" do
      click_button "Add related external link"
      within all(".js-add-another__fieldset")[0] do
        fill_in "Title", with: "title one"
        fill_in "URL", with: "http://one.com"
      end
      click_button "Add related external link"
      within all(".js-add-another__fieldset")[1] do
        fill_in "Title", with: "second title"
        fill_in "URL", with: "http://second.com"
      end
      click_button "Add related external link"
      within all(".js-add-another__fieldset")[2] do
        fill_in "Title", with: "title three"
        fill_in "URL", with: "http://three.com"
      end
      within all(".js-add-another__fieldset")[0] do
        click_button "Delete"
      end
      click_button "Save"

      event_data = get_event_data

      # Event data fired when user clicks “Add related external link”
      assert_equal "added", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Related external links", event_data[0]["section"]
      assert_equal "Add related external link", event_data[0]["text"]
      # Requires change in add-another.js to retrieve the following values
      # assert_equal "1", event_data[0]["index"]["index_section"]
      # assert_equal "1", event_data[0]["index"]["index_section_count"]
      # assert_equal "add another", event_data[1]["type"]

      # Event fired when user fills in “Title” under “Link 1”
      assert_equal "select", event_data[1]["action"]
      assert_equal "select_content", event_data[1]["event_name"]
      assert_equal "9", event_data[1]["text"]
      assert_equal "1", event_data[1]["index"]["index_section"]
      assert_equal "1", event_data[1]["index"]["index_section_count"]
      # Requires change in Ga4-form-change-tracker to retrieve the following values
      # assert_equal "Link 1 - Title", event_data[1]["section"]
      # assert_equal "add another", event_data[1]["type"]

      # Event fired when user fills in URL” under “Link 1”
      assert_equal "select", event_data[2]["action"]
      assert_equal "select_content", event_data[2]["event_name"]
      assert_equal "14", event_data[2]["text"]
      assert_equal "1", event_data[2]["index"]["index_section"]
      assert_equal "1", event_data[2]["index"]["index_section_count"]
      # Requires change in Ga4-form-change-tracker to retrieve the following values
      # assert_equal "Link 1 - URL", event_data[2]["section"]
      # assert_equal "add another", event_data[2]["type"]

      # Event data fired when user clicks “Add related external link”
      assert_equal "added", event_data[3]["action"]
      assert_equal "select_content", event_data[3]["event_name"]
      assert_equal "Related external links", event_data[3]["section"]
      assert_equal "Add related external link", event_data[3]["text"]
      assert_equal "1", event_data[3]["index"]["index_section"]
      assert_equal "1", event_data[3]["index"]["index_section_count"]
      assert_equal "add another", event_data[3]["type"]

      # Event fired when user fills in “Title” under “Link 2”
      assert_equal "select", event_data[4]["action"]
      assert_equal "select_content", event_data[4]["event_name"]
      assert_equal "12", event_data[4]["text"]
      assert_equal "1", event_data[4]["index"]["index_section"]
      assert_equal "1", event_data[4]["index"]["index_section_count"]
      # Requires change in Ga4-form-change-tracker to retrieve the following values
      # assert_equal "Link 1 - Title", event_data[4]["section"]
      # assert_equal "add another", event_data[4]["type"]

      # Event fired when user fills in URL” under “Link 2”
      assert_equal "select", event_data[5]["action"]
      assert_equal "select_content", event_data[5]["event_name"]
      assert_equal "17", event_data[5]["text"]
      assert_equal "1", event_data[5]["index"]["index_section"]
      assert_equal "1", event_data[5]["index"]["index_section_count"]
      # Requires change in Ga4-form-change-tracker to retrieve the following values
      # assert_equal "Link 1 - URL", event_data[5]["section"]
      # assert_equal "add another", event_data[5]["type"]

      # Event data fired when user clicks “Add related external link”
      assert_equal "added", event_data[6]["action"]
      assert_equal "select_content", event_data[6]["event_name"]
      assert_equal "Related external links", event_data[6]["section"]
      assert_equal "Add related external link", event_data[6]["text"]
      assert_equal "add another", event_data[6]["type"]
      # Requires change in add-another.js to retrieve the following values
      # assert_equal "1", event_data[6]["index"]["index_section"]
      # assert_equal "1", event_data[6]["index"]["index_section_count"]

      # Event fired when user fills in “Title” under “Link 3”
      assert_equal "select", event_data[7]["action"]
      assert_equal "select_content", event_data[7]["event_name"]
      assert_equal "11", event_data[7]["text"]
      assert_equal "1", event_data[7]["index"]["index_section"]
      assert_equal "1", event_data[7]["index"]["index_section_count"]
      # Requires change in Ga4-form-change-tracker to retrieve the following values
      # assert_equal "Link 1 - Title", event_data[7]["section"]
      # assert_equal "add another", event_data[7]["type"]

      # Event fired when user fills in URL” under “Link 3”
      assert_equal "select", event_data[8]["action"]
      assert_equal "select_content", event_data[8]["event_name"]
      assert_equal "16", event_data[8]["text"]
      assert_equal "1", event_data[8]["index"]["index_section"]
      assert_equal "1", event_data[8]["index"]["index_section_count"]
      # Requires change in Ga4-form-change-tracker to retrieve the following values
      # assert_equal "Link 1 - URL", event_data[5]["section"]
      # assert_equal "add another", event_data[8]["type"]

      # "Delete" for "Link 1" clicked
      assert_equal "deleted", event_data[9]["action"]
      assert_equal "select_content", event_data[9]["event_name"]
      assert_equal "Related external links", event_data[9]["section"]
      assert_equal "Delete", event_data[9]["text"]
      assert_equal "add another", event_data[9]["type"]
      # Requires change in add-another.js to retrieve the following values
      # assert_equal "1", event_data[9]["index"]["index_section"]
      # assert_equal "1", event_data[9]["index"]["index_section_count"]

      # Form submitted
      assert_equal "Save", event_data[10]["action"]
      assert_equal "form_response", event_data[10]["event_name"]
      assert_equal "Related external links", event_data[10]["section"]
      assert_equal "Answer", event_data[10]["tool_name"]
      assert_equal "edit", event_data[10]["type"]
      # Requires change in add-another.js to retrieve the following value
      # assert_equal "{"Related external links\":\"12, 17, 11, 16\"}"}", event_data[10]["text"]
    end
  end
end
