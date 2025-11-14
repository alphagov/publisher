require "integration_test_helper"

class Ga4TrackingTest < JavascriptIntegrationTest
  setup do
    FactoryBot.create(:user, :govuk_editor, name: "Test User")
    @edition = FactoryBot.create(:answer_edition, title: "Answer edition")

    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:ga4_form_tracking, true)
  end

  context "Edit page" do
    setup do
      visit edition_path(@edition)
      disable_form_submit
    end

    should "render the correct ga4 data-attributes on the form" do
      get_form_data_attributes

      assert_includes @form_module_data, "ga4-form-tracker"
      assert_equal @form_ga4_event_data["action"], "Save"
      assert_equal @form_ga4_event_data["event_name"], "form_response"
      assert_equal @form_ga4_event_data["section"], "Answer edition"
      assert_equal @form_ga4_event_data["tool_name"], "Answer"
      assert_equal @form_ga4_event_data["type"], "edit"

      test_common_form_attributes
    end

    should "render the correct ga4 data-attributes on the form elements" do
      title_field_data = get_field_index_data(find("input[name='edition[title]']"))
      metatag_field_data = get_field_index_data(find("textarea[name='edition[overview]']"))
      body_field_data = get_field_index_data(find("textarea[name='edition[body]']"))
      beta_field_data = get_field_index_data(find("fieldset"))

      assert_equal 1, title_field_data["index_section"]
      assert_equal 4, title_field_data["index_section_count"]
      assert_equal 2, metatag_field_data["index_section"]
      assert_equal 4, metatag_field_data["index_section_count"]
      assert_equal 3, body_field_data["index_section"]
      assert_equal 4, body_field_data["index_section_count"]
      assert_equal 4, beta_field_data["index_section"]
      assert_equal 4, beta_field_data["index_section_count"]
    end

    should "push the correct values to the dataLayer when events are triggered" do
      fill_in "Title", with: "The title"
      fill_in "Meta tag description", with: "the-meta-tag-description"
      fill_in "Body", with: "The body text"
      find("label", text: "Yes").click
      find("label", text: "No").click
      click_button "Save"

      data_layer = evaluate_script("window.dataLayer")

      event_data_title = data_layer[data_layer.count - 6]["event_data"]
      event_data_meta = data_layer[data_layer.count - 5]["event_data"]
      event_data_body = data_layer[data_layer.count - 4]["event_data"]
      event_data_radio_yes = data_layer[data_layer.count - 3]["event_data"]
      event_data_radio_no = data_layer[data_layer.count - 2]["event_data"]
      event_data_save = data_layer[data_layer.count - 1]["event_data"]

      assert_equal "select", event_data_title["action"]
      assert_equal "select_content", event_data_title["event_name"]
      assert_equal "Title", event_data_title["section"]
      assert_equal "9", event_data_title["text"]
      assert_equal "1", event_data_title["index"]["index_section"]
      assert_equal "4", event_data_title["index"]["index_section_count"]

      assert_equal "select", event_data_meta["action"]
      assert_equal "select_content", event_data_meta["event_name"]
      assert_equal "Meta tag description", event_data_meta["section"]
      assert_equal "24", event_data_meta["text"]
      assert_equal "2", event_data_meta["index"]["index_section"]
      assert_equal "4", event_data_meta["index"]["index_section_count"]

      assert_equal "select", event_data_body["action"]
      assert_equal "select_content", event_data_body["event_name"]
      assert_equal "Body", event_data_body["section"]
      assert_equal "13", event_data_body["text"]
      assert_equal "3", event_data_body["index"]["index_section"]
      assert_equal "4", event_data_body["index"]["index_section_count"]

      assert_equal "select", event_data_radio_yes["action"]
      assert_equal "select_content", event_data_radio_yes["event_name"]
      assert_equal "Is this beta content?", event_data_radio_yes["section"]
      assert_equal "Yes", event_data_radio_yes["text"]
      assert_equal "4", event_data_radio_yes["index"]["index_section"]
      assert_equal "4", event_data_radio_yes["index"]["index_section_count"]

      assert_equal "select", event_data_radio_no["action"]
      assert_equal "select_content", event_data_radio_no["event_name"]
      assert_equal "Is this beta content?", event_data_radio_no["section"]
      assert_equal "No", event_data_radio_no["text"]
      assert_equal "4", event_data_radio_no["index"]["index_section"]
      assert_equal "4", event_data_radio_no["index"]["index_section_count"]

      assert_equal "Save", event_data_save["action"]
      assert_equal "form_response", event_data_save["event_name"]
      assert_equal "Answer edition", event_data_save["section"]
      assert_equal "{\"Title\":\"9\",\"Meta tag description\":\"24\",\"Body\":\"13\",\"Is this beta content?\":\"No\"}", event_data_save["text"]
      assert_equal "Answer", event_data_save["tool_name"]
      assert_equal "edit", event_data_save["type"]
    end
  end

  context "Edit assignee page" do
    setup do
      visit edition_path(@edition)

      within all(".govuk-summary-list__row")[0] do
        click_link("Edit")
      end

      disable_form_submit
    end

    should "render the correct ga4 data-attributes on the form" do
      get_form_data_attributes

      assert_includes @form_module_data, "ga4-form-tracker"
      assert_equal @form_ga4_event_data["action"], "Save"
      assert_equal @form_ga4_event_data["event_name"], "form_response"
      assert_equal @form_ga4_event_data["section"], "Assign person"
      assert_equal @form_ga4_event_data["tool_name"], "Answer"
      assert_equal @form_ga4_event_data["type"], "edit"

      test_common_form_attributes
    end

    should "render the correct ga4 data-attributes on the form elements" do
      assign_field_data = get_field_index_data(find("fieldset"))

      assert_equal 1, assign_field_data["index_section"]
      assert_equal 1, assign_field_data["index_section_count"]
    end

    should "push the correct values to the dataLayer when events are triggered" do
      find("label", text: "Test User").click
      click_button "Save"

      data_layer = evaluate_script("window.dataLayer")

      event_data_radio_user = data_layer[data_layer.count - 2]["event_data"]
      event_data_save = data_layer[data_layer.count - 1]["event_data"]

      assert_equal "select", event_data_radio_user["action"]
      assert_equal "select_content", event_data_radio_user["event_name"]
      assert_equal "Choose a person to assign", event_data_radio_user["section"]
      assert_equal "Test User", event_data_radio_user["text"]
      assert_equal "1", event_data_radio_user["index"]["index_section"]
      assert_equal "1", event_data_radio_user["index"]["index_section_count"]

      assert_equal "Save", event_data_save["action"]
      assert_equal "form_response", event_data_save["event_name"]
      assert_equal "Assign person", event_data_save["section"]
      assert_equal "{\"Choose a person to assign\":\"Test User\"}", event_data_save["text"]
      assert_equal "Answer", event_data_save["tool_name"]
      assert_equal "edit", event_data_save["type"]
    end
  end

private

  def disable_form_submit
    # Disable submission of the form so that all event data can be gathered
    # including the data collected on the "Save" (or equivalent) button being clicked
    execute_script("document.querySelector('form').addEventListener('submit',function(e){e.preventDefault()})")
  end

  def get_form_data_attributes
    form = find("form")
    @form_module_data = form["data-module"]
    @form_ga4_event_data = JSON.parse(form["data-ga4-form"])
  end

  def test_common_form_attributes
    assert page.has_css?("form[data-ga4-form-include-text]")
    assert page.has_css?("form[data-ga4-form-change-tracking]")
    assert page.has_css?("form[data-ga4-form-record-json]")
    assert page.has_css?("form[data-ga4-form-use-text-count]")
  end

  def get_field_index_data(field)
    JSON.parse(field["data-ga4-index"])
  end
end
