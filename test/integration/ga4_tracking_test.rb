require "integration_test_helper"

class Ga4TrackingTest < JavascriptIntegrationTest
  setup do
    FactoryBot.create(:user, :govuk_editor, name: "Test User")
    @govuk_requester = FactoryBot.create(:user, :govuk_editor)
    @edition = FactoryBot.create(:answer_edition, title: "Answer edition")

    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:ga4_form_tracking, true)
  end

  context "Edit page" do
    setup do
      visit edition_path(@edition)
      disable_form_submit
    end

    should "push the correct values to the dataLayer when events are triggered" do
      fill_in "Title", with: "The title"
      fill_in "Meta tag description", with: "the-meta-tag-description"
      fill_in "Body", with: "The body text"
      find("label", text: "Yes").click
      find("label", text: "No").click
      click_button "Save"

      event_data = get_event_data

      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Title", event_data[0]["section"]
      assert_equal "9", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "4", event_data[0]["index"]["index_section_count"]

      assert_equal "select", event_data[1]["action"]
      assert_equal "select_content", event_data[1]["event_name"]
      assert_equal "Meta tag description", event_data[1]["section"]
      assert_equal "24", event_data[1]["text"]
      assert_equal "2", event_data[1]["index"]["index_section"]
      assert_equal "4", event_data[1]["index"]["index_section_count"]

      assert_equal "select", event_data[2]["action"]
      assert_equal "select_content", event_data[2]["event_name"]
      assert_equal "Body", event_data[2]["section"]
      assert_equal "13", event_data[2]["text"]
      assert_equal "3", event_data[2]["index"]["index_section"]
      assert_equal "4", event_data[2]["index"]["index_section_count"]

      assert_equal "select", event_data[3]["action"]
      assert_equal "select_content", event_data[3]["event_name"]
      assert_equal "Is this beta content?", event_data[3]["section"]
      assert_equal "Yes", event_data[3]["text"]
      assert_equal "4", event_data[3]["index"]["index_section"]
      assert_equal "4", event_data[3]["index"]["index_section_count"]

      assert_equal "select", event_data[4]["action"]
      assert_equal "select_content", event_data[4]["event_name"]
      assert_equal "Is this beta content?", event_data[4]["section"]
      assert_equal "No", event_data[4]["text"]
      assert_equal "4", event_data[4]["index"]["index_section"]
      assert_equal "4", event_data[4]["index"]["index_section_count"]

      assert_equal "Save", event_data[5]["action"]
      assert_equal "form_response", event_data[5]["event_name"]
      assert_equal "Answer edition", event_data[5]["section"]
      assert_equal "{\"Title\":\"9\",\"Meta tag description\":\"24\",\"Body\":\"13\",\"Is this beta content?\":\"No\"}", event_data[5]["text"]
      assert_equal "Answer", event_data[5]["tool_name"]
      assert_equal "edit", event_data[5]["type"]
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

    should "push the correct values to the dataLayer when events are triggered" do
      find("label", text: "Test User").click
      click_button "Save"

      event_data = get_event_data

      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Choose a person to assign", event_data[0]["section"]
      assert_equal "Test User", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "1", event_data[0]["index"]["index_section_count"]

      assert_equal "Save", event_data[1]["action"]
      assert_equal "form_response", event_data[1]["event_name"]
      assert_equal "Assign person", event_data[1]["section"]
      assert_equal "{\"Choose a person to assign\":\"Test User\"}", event_data[1]["text"]
      assert_equal "Answer", event_data[1]["tool_name"]
      assert_equal "edit", event_data[1]["type"]
    end
  end

  context "Assign 21 reviewer page" do
    setup do
      @edition.state = "in_review"
      @edition.review_requested_at = 1.day.ago
      @edition.save!
      @edition.actions.create!(
        request_type: Action::REQUEST_AMENDMENTS,
        requester_id: @govuk_requester.id,
      )

      visit edition_path(@edition)

      within all(".govuk-summary-list__row")[3] do
        click_link("Edit")
      end

      disable_form_submit
    end

    should "push the correct values to the dataLayer when events are triggered" do
      page.find("label", text: "Test User").click
      click_button "Save"

      event_data = get_event_data

      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Choose a person to assign", event_data[0]["section"]
      assert_equal "Test User", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "1", event_data[0]["index"]["index_section_count"]

      assert_equal "Save", event_data[1]["action"]
      assert_equal "form_response", event_data[1]["event_name"]
      assert_equal "Assign 2i reviewer", event_data[1]["section"]
      assert_equal "{\"Choose a person to assign\":\"Test User\"}", event_data[1]["text"]
      assert_equal "Answer", event_data[1]["tool_name"]
      assert_equal "edit", event_data[1]["type"]
    end
  end

  context "Send to 2i page" do
    setup do
      visit edition_path(@edition)

      click_link("Send to 2i")

      disable_form_submit
    end

    should "push the correct values to the dataLayer when events are triggered" do
      fill_in "Comment (optional)", with: "Some comment"
      click_button "Send to 2i"

      event_data = get_event_data

      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Comment (optional)", event_data[0]["section"]
      assert_equal "12", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "1", event_data[0]["index"]["index_section_count"]

      assert_equal "Save", event_data[1]["action"]
      assert_equal "form_response", event_data[1]["event_name"]
      assert_equal "Send to 2i", event_data[1]["section"]
      assert_equal "{\"Comment (optional)\":\"12\"}", event_data[1]["text"]
      assert_equal "Answer", event_data[1]["tool_name"]
      assert_equal "edit", event_data[1]["type"]
    end
  end

private

  def disable_form_submit
    # Disable submission of the form so that all event data can be gathered
    # including the data collected on the "Save" (or equivalent) button being clicked
    execute_script("document.querySelector('form').addEventListener('submit',function(e){e.preventDefault()})")
  end

  def get_event_data
    # Gets the data generated by user events up to and including submitting the form
    data_layer_events = evaluate_script("window.dataLayer")
    event_data = []

    data_layer_events.each do |event|
      if event["event_data"]
        event_data << event["event_data"]
      end
    end

    event_data
  end
end
