require "integration_test_helper"
require "support/ga4_test_helpers"

class Ga4TrackingTaggingTest < JavascriptIntegrationTest
  include Ga4TestHelpers

  setup do
    FactoryBot.create(:user, :govuk_editor, name: "Test User")
    @govuk_requester = FactoryBot.create(:user, :govuk_editor, :skip_review)
    @edition = FactoryBot.create(:answer_edition, title: "Answer edition")

    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:ga4_form_tracking, true)
  end

  context "Set GOV.UK breadcrumb page" do
    setup do
      stub_linkables_with_data
      visit tagging_breadcrumb_page_edition_path(@edition)
      disable_form_submit
    end

    should "add breadcrumb selection events to the dataLayer" do
      # Select an option
      find("label", text: "Benefits and financial support for families (draft)").click
      # Select a different option
      find("label", text: "Capital Gains Tax").click
      # Save selection
      click_button "Save"

      event_data = get_event_data

      # "Benefits and financial support for families (draft)" selected
      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Benefits", event_data[0]["section"]
      assert_equal "Benefits and financial support for families (draft)", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "2", event_data[0]["index"]["index_section_count"]

      # "Benefits and financial support for families (draft)" deselected, "Capital Gains Tax" selected
      assert_equal "select", event_data[1]["action"]
      assert_equal "select_content", event_data[1]["event_name"]
      assert_equal "Tax", event_data[1]["section"]
      assert_equal "Capital Gains Tax", event_data[1]["text"]
      assert_equal "2", event_data[1]["index"]["index_section"]
      assert_equal "2", event_data[1]["index"]["index_section_count"]

      # Form submitted with "Capital Gains Tax" selected
      assert_equal "Save", event_data[2]["action"]
      assert_equal "form_response", event_data[2]["event_name"]
      assert_equal "Set GOV.UK breadcrumb", event_data[2]["section"]
      assert_equal "{\"Tax\":\"Capital Gains Tax\"}", event_data[2]["text"]
      assert_equal "Answer", event_data[2]["tool_name"]
      assert_equal "edit", event_data[2]["type"]
    end
  end

  context "Remove GOVUK breadcrumb page" do
    setup do
      stub_linkables_with_data
      visit tagging_remove_breadcrumb_page_edition_path(@edition)
      disable_form_submit
    end

    should "add breadcrumb removal events to the dataLayer" do
      # Select an option
      find("label", text: "Yes, remove the breadcrumb").click
      # Select a different option
      find("label", text: "No, keep the breadcrumb").click
      # Save selection
      click_button "Save"

      event_data = get_event_data

      # "Yes, remove the breadcrumb" selected
      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Are you sure you want to remove the breadcrumb?", event_data[0]["section"]
      assert_equal "Yes, remove the breadcrumb", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "1", event_data[0]["index"]["index_section_count"]

      # "Yes, remove the breadcrumb" deselected, "No, keep the breadcrumb" selected
      assert_equal "select", event_data[1]["action"]
      assert_equal "select_content", event_data[1]["event_name"]
      assert_equal "Are you sure you want to remove the breadcrumb?", event_data[1]["section"]
      assert_equal "No, keep the breadcrumb", event_data[1]["text"]
      assert_equal "1", event_data[1]["index"]["index_section"]
      assert_equal "1", event_data[1]["index"]["index_section_count"]

      # Form submitted with "No, keep the breadcrumb" selected
      assert_equal "Save", event_data[2]["action"]
      assert_equal "form_response", event_data[2]["event_name"]
      assert_equal "Are you sure you want to remove the breadcrumb?", event_data[2]["section"]
      assert_equal "{\"Are you sure you want to remove the breadcrumb?\":\"No, keep the breadcrumb\"}", event_data[2]["text"]
      assert_equal "Answer", event_data[2]["tool_name"]
      assert_equal "edit", event_data[2]["type"]
    end
  end

  context "Tag browse pages page" do
    setup do
      stub_linkables
      visit tagging_mainstream_browse_pages_page_edition_path(@edition)
      disable_form_submit
    end

    should "add browse pages selection events to the dataLayer" do
      # Select three options
      find("label", text: "Benefits and financial support for families").click
      find("label", text: "VAT").click
      find("label", text: "Capital Gains Tax").click
      # Deselect one selected option
      find("label", text: "VAT").click
      click_button "Save"

      event_data = get_event_data

      # "Benefits and financial support for families (draft)" selected
      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Benefits", event_data[0]["section"]
      assert_equal "Benefits and financial support for families (draft)", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "2", event_data[0]["index"]["index_section_count"]

      # "VAT" selected
      assert_equal "select", event_data[1]["action"]
      assert_equal "select_content", event_data[1]["event_name"]
      assert_equal "Tax", event_data[1]["section"]
      assert_equal "VAT", event_data[1]["text"]
      assert_equal "2", event_data[1]["index"]["index_section"]
      assert_equal "2", event_data[1]["index"]["index_section_count"]

      # "Capital Gains Tax" selected
      assert_equal "select", event_data[2]["action"]
      assert_equal "select_content", event_data[2]["event_name"]
      assert_equal "Tax", event_data[2]["section"]
      assert_equal "Capital Gains Tax", event_data[2]["text"]
      assert_equal "2", event_data[2]["index"]["index_section"]
      assert_equal "2", event_data[2]["index"]["index_section_count"]

      # "VAT" deselected
      assert_equal "remove", event_data[3]["action"]
      assert_equal "select_content", event_data[3]["event_name"]
      assert_equal "Tax", event_data[3]["section"]
      assert_equal "VAT", event_data[3]["text"]
      assert_equal "2", event_data[3]["index"]["index_section"]
      assert_equal "2", event_data[3]["index"]["index_section_count"]

      # Form submitted with "Benefits and financial support for families (draft)" and "Capital Gains Tax" selected
      assert_equal "Save", event_data[4]["action"]
      assert_equal "form_response", event_data[4]["event_name"]
      assert_equal "Tag browse pages", event_data[4]["section"]
      assert_equal "{\"Benefits\":\"Benefits and financial support for families (draft)\",\"Tax\":\"Capital Gains Tax\"}", event_data[4]["text"]
      assert_equal "Answer", event_data[4]["tool_name"]
      assert_equal "edit", event_data[4]["type"]
    end
  end

  context "Tag to an organisation page" do
    setup do
      stub_linkables
      visit tagging_organisations_page_edition_path(@edition)
      disable_form_submit
      # Activate search with select so we can interact with it
      find(".gem-c-select-with-search").click
    end

    should "add multiple organisation selection events to the dataLayer" do
      # Select two options
      within(".choices__list--dropdown .choices__list") do
        div = find_all("div")
        div[0].click
        div[1].click
      end

      click_button "Save"

      event_data = get_event_data

      # "Department for Education" selected
      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Organisations", event_data[0]["section"]
      assert_equal "Department for Education", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "1", event_data[0]["index"]["index_section_count"]

      # "Student Loans Company" selected
      assert_equal "select", event_data[1]["action"]
      assert_equal "select_content", event_data[1]["event_name"]
      assert_equal "Organisations", event_data[1]["section"]
      assert_equal "Student Loans Company", event_data[1]["text"]
      assert_equal "1", event_data[1]["index"]["index_section"]
      assert_equal "1", event_data[1]["index"]["index_section_count"]

      # Form submitted with "Department for Education" and "Student Loans Company" selected
      assert_equal "Save", event_data[2]["action"]
      assert_equal "form_response", event_data[2]["event_name"]
      assert_equal "Tag organisations", event_data[2]["section"]
      assert_equal "{\"Organisations\":\"2\"}", event_data[2]["text"]
      assert_equal "Answer", event_data[2]["tool_name"]
      assert_equal "edit", event_data[2]["type"]
    end

    should "add single organisation selection events to the dataLayer" do
      # Select one organisation
      within(".choices__list--dropdown .choices__list") do
        div = find_all("div")
        div[1].click
      end

      click_button "Save"

      event_data = get_event_data

      # "Student Loans Company" selected
      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Organisations", event_data[0]["section"]
      assert_equal "Student Loans Company", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "1", event_data[0]["index"]["index_section_count"]

      # Form submitted with "Student Loans Company" selected
      assert_equal "Save", event_data[1]["action"]
      assert_equal "form_response", event_data[1]["event_name"]
      assert_equal "Tag organisations", event_data[1]["section"]
      assert_equal "{\"Organisations\":\"Student Loans Company\"}", event_data[1]["text"]
      assert_equal "Answer", event_data[1]["tool_name"]
      assert_equal "edit", event_data[1]["type"]
    end
  end

  context "Tag to related content page" do
    setup do
      stub_linkables
      visit tagging_related_content_page_edition_path(@edition)
      disable_form_submit
    end

    should "add related content selection events to the dataLayer" do
      # Fill in value for Related content 1
      within all(".js-add-another__fieldset")[0] do
        fill_in "URL or path", with: "/pay-vat"
      end
      # Click "Add another related content item"
      click_button "Add another related content item"
      # Fill in value for Related content 2
      within all(".js-add-another__fieldset")[1] do
        fill_in "URL or path", with: "/universal-credit"
      end
      # Click "Add another related content item"
      click_button "Add another related content item"
      # Fill in value for Related content 3
      within all(".js-add-another__fieldset")[2] do
        fill_in "URL or path", with: "/company-tax-returns"
      end
      # Delete Related content 1
      within all(".js-add-another__fieldset")[0] do
        click_button "Delete"
      end
      # Save values
      click_button "Save"

      event_data = get_event_data

      # "Related content 1" field completed
      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "URL or path", event_data[0]["section"]
      assert_equal "8", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "1", event_data[0]["index"]["index_section_count"]

      # "Add another related content item" clicked
      assert_equal "added", event_data[1]["action"]
      assert_equal "select_content", event_data[1]["event_name"]
      assert_equal "Tag related content", event_data[1]["section"]
      assert_equal "Add another related content item", event_data[1]["text"]
      assert_equal "1", event_data[1]["index"]["index_section"]
      assert_equal "1", event_data[1]["index"]["index_section_count"]

      # "Related content 2" field completed
      assert_equal "select", event_data[2]["action"]
      assert_equal "select_content", event_data[2]["event_name"]
      assert_equal "URL or path", event_data[2]["section"]
      assert_equal "17", event_data[2]["text"]
      # TODO: Confirm expected values for these
      # assert_equal "1", event_data[2]["index"]["index_section"]
      # assert_equal "1", event_data[2]["index"]["index_section_count"]
 
      # "Add another related content item" clicked
      assert_equal "added", event_data[3]["action"]
      assert_equal "select_content", event_data[3]["event_name"]
      assert_equal "Tag related content", event_data[3]["section"]
      assert_equal "Add another related content item", event_data[3]["text"]
      assert_equal "2", event_data[3]["index"]["index_section"]
      assert_equal "2", event_data[3]["index"]["index_section_count"]

      # "Related content 3" field completed
      assert_equal "select", event_data[4]["action"]
      assert_equal "select_content", event_data[4]["event_name"]
      assert_equal "URL or path", event_data[4]["section"]
      assert_equal "20", event_data[4]["text"]
      # TODO: Confirm expected values for these
      # assert_equal "1", event_data[4]["index"]["index_section"]
      # assert_equal "1", event_data[4]["index"]["index_section_count"]

      # "Delete" for "Related content 1" clicked
      assert_equal "deleted", event_data[5]["action"]
      assert_equal "select_content", event_data[5]["event_name"]
      assert_equal "Tag related content", event_data[5]["section"]
      assert_equal "Delete", event_data[5]["text"]
      assert_equal "add another", event_data[5]["type"]
      assert_equal "1", event_data[5]["index"]["index_section"]
      assert_equal "3", event_data[5]["index"]["index_section_count"]

      # form submitted with "/universal-credit" and "/company-tax-returns" selected
      assert_equal "Save", event_data[6]["action"]
      assert_equal "form_response", event_data[6]["event_name"]
      assert_equal "Tag related content", event_data[6]["section"]
      # TODO: Confirm expected values for this
      # assert_equal "{\"Related content 1\":\"/universal-credit\",\"Related content 2\":\"/company-tax-returns\"}", event_data[6]["text"]
      assert_equal "Answer", event_data[6]["tool_name"]
      # TODO: Confirm expected values for this
      # assert_equal "new", event_data[6]["type"]
   end
  end
end
