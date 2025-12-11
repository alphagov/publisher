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
end
