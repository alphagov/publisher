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

    should "push the correct values to the dataLayer when events are triggered" do
      find("label", text: "Benefits and financial support for families (draft)").click
      find("label", text: "Capital Gains Tax").click
      click_button "Save"

      event_data = get_event_data

      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Benefits", event_data[0]["section"]
      assert_equal "Benefits and financial support for families (draft)", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "2", event_data[0]["index"]["index_section_count"]

      assert_equal "select", event_data[1]["action"]
      assert_equal "select_content", event_data[1]["event_name"]
      assert_equal "Tax", event_data[1]["section"]
      assert_equal "Capital Gains Tax", event_data[1]["text"]
      assert_equal "2", event_data[1]["index"]["index_section"]
      assert_equal "2", event_data[1]["index"]["index_section_count"]

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

    should "push the correct values to the dataLayer when events are triggered" do
      find("label", text: "Yes, remove the breadcrumb").click
      find("label", text: "No, keep the breadcrumb").click
      click_button "Save"

      event_data = get_event_data

      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Are you sure you want to remove the breadcumb?", event_data[0]["section"]
      assert_equal "Yes, remove the breadcrumb", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "1", event_data[0]["index"]["index_section_count"]

      assert_equal "select", event_data[1]["action"]
      assert_equal "select_content", event_data[1]["event_name"]
      assert_equal "Are you sure you want to remove the breadcumb?", event_data[1]["section"]
      assert_equal "No, keep the breadcrumb", event_data[1]["text"]
      assert_equal "1", event_data[1]["index"]["index_section"]
      assert_equal "1", event_data[1]["index"]["index_section_count"]

      assert_equal "Save", event_data[2]["action"]
      assert_equal "form_response", event_data[2]["event_name"]
      assert_equal "Are you sure you want to remove the breadcumb?", event_data[2]["section"]
      assert_equal "{\"Are you sure you want to remove the breadcumb?\":\"No, keep the breadcrumb\"}", event_data[2]["text"]
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

    should "push the correct values to the dataLayer when events are triggered" do
      # Select options
      find("label", text: "Benefits and financial support for families").click
      find("label", text: "VAT").click
      find("label", text: "Capital Gains Tax").click
      # Deselect a selected option
      find("label", text: "VAT").click
      click_button "Save"

      event_data = get_event_data

      # Select "Benefits and financial support for families (draft)"
      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Benefits", event_data[0]["section"]
      assert_equal "Benefits and financial support for families (draft)", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "2", event_data[0]["index"]["index_section_count"]

      # Select "VAT"
      assert_equal "select", event_data[1]["action"]
      assert_equal "select_content", event_data[1]["event_name"]
      assert_equal "Tax", event_data[1]["section"]
      assert_equal "VAT", event_data[1]["text"]
      assert_equal "2", event_data[1]["index"]["index_section"]
      assert_equal "2", event_data[1]["index"]["index_section_count"]

      # Select "Capital Gains Tax"
      assert_equal "select", event_data[2]["action"]
      assert_equal "select_content", event_data[2]["event_name"]
      assert_equal "Tax", event_data[2]["section"]
      assert_equal "Capital Gains Tax", event_data[2]["text"]
      assert_equal "2", event_data[2]["index"]["index_section"]
      assert_equal "2", event_data[2]["index"]["index_section_count"]

      # Deselect "VAT"
      assert_equal "remove", event_data[3]["action"]
      assert_equal "select_content", event_data[3]["event_name"]
      assert_equal "Tax", event_data[3]["section"]
      assert_equal "VAT", event_data[3]["text"]
      assert_equal "2", event_data[3]["index"]["index_section"]
      assert_equal "2", event_data[3]["index"]["index_section_count"]

      # Save selections
      assert_equal "Save", event_data[4]["action"]
      assert_equal "form_response", event_data[4]["event_name"]
      assert_equal "Tag browse pages", event_data[4]["section"]
      assert_equal "{\"Benefits\":\"Benefits and financial support for families (draft)\",\"Tax\":\"Capital Gains Tax\"}", event_data[4]["text"]
      assert_equal "Answer", event_data[4]["tool_name"]
      assert_equal "edit", event_data[4]["type"]
    end
  end
end
