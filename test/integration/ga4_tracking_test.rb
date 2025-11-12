require "integration_test_helper"

class Ga4TrackingTest < JavascriptIntegrationTest
  setup do
    FactoryBot.create(:user, :govuk_editor)

    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:ga4_form_tracking, true)
  end

  context "Edit page" do
    setup do
      edition = FactoryBot.create(:answer_edition, title: "Answer edition")
      visit edition_path(edition)
    end

    should "render the correct ga4 data-attributes on the form" do
      form = page.find("form")
      form_module_data = form["data-module"]
      form_ga4_event_data = JSON.parse(form["data-ga4-form"])

      assert_includes form_module_data, "ga4-form-tracker"
      assert_equal form_ga4_event_data["action"], "Save"
      assert_equal form_ga4_event_data["event_name"], "form_response"
      assert_equal form_ga4_event_data["section"], "Edit edition"
      assert_equal form_ga4_event_data["tool_name"], "publisher"
      assert_equal form_ga4_event_data["type"], "edit"

      assert page.has_css?("form[data-ga4-form-include-text]")
      assert page.has_css?("form[data-ga4-form-change-tracking]")
      assert page.has_css?("form[data-ga4-form-record-json]")
      assert page.has_css?("form[data-ga4-form-use-text-count]")
    end

    should "render the correct ga4 data-attributes on the form elements" do
      title_field = page.find("input[name='edition[title]']")
      metatag_field = page.find("textarea[name='edition[overview]']")
      body_field = page.find("textarea[name='edition[body]']")
      beta_field = page.find("fieldset")

      title_field_data = JSON.parse(title_field["data-ga4-index"])
      metatag_field_data = JSON.parse(metatag_field["data-ga4-index"])
      body_field_data = JSON.parse(body_field["data-ga4-index"])
      beta_field_data = JSON.parse(beta_field["data-ga4-index"])

      assert_equal 1, title_field_data["index_section"]
      assert_equal 4, title_field_data["index_section_count"]
      assert_equal 2, metatag_field_data["index_section"]
      assert_equal 4, metatag_field_data["index_section_count"]
      assert_equal 3, body_field_data["index_section"]
      assert_equal 4, body_field_data["index_section_count"]
      assert_equal 4, beta_field_data["index_section"]
      assert_equal 4, beta_field_data["index_section_count"]
    end
  end
end
