require "integration_test_helper"
require "support/ga4_test_helpers"

class Ga4TrackingEditTest < JavascriptIntegrationTest
  include Ga4TestHelpers

  setup do
    setup_users

    @edition = FactoryBot.create(:answer_edition, title: "Answer edition")
    @guide_edition = FactoryBot.create(:guide_edition, title: "Guide edition")
    @assigned_edition = FactoryBot.create(:edition, assigned_to: @author, created_at: 5.days.ago)
    @in_review_edition = FactoryBot.create(:edition, :in_review, reviewer: @reviewer, created_at: 6.days.ago)
    @ready_edition = FactoryBot.create(:edition, :ready, created_at: 6.days.ago)

    @assigned_edition.actions.create! request_type: Action::ASSIGN, requester_id: @author.id, created_at: 4.days.ago
    @in_review_edition.actions.create! request_type: Action::REQUEST_REVIEW, requester_id: @requester.id, created_at: Time.zone.now, comment: "Requesting review"

    @test_strategy.switch!(:ga4_form_tracking, true)
  end

  context "Edit page" do
    setup do
      visit edition_path(@edition)
    end

    should "push the correct values to the dataLayer when events are triggered" do
      disable_form_submit

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

    should "push the correct values to the dataLayer when a form error is triggered" do
      fill_in "Title", with: ""
      click_button "Save"

      assert page.has_css?(".gem-c-error-summary")

      event_data = get_event_data

      assert_equal "error", event_data[0]["action"]
      assert_equal "form_error", event_data[0]["event_name"]
      assert_equal "Edit edition", event_data[0]["type"]
      assert_equal "Enter a title", event_data[0]["text"]
      assert_equal "Title", event_data[0]["section"]
      assert_equal "Answer", event_data[0]["tool_name"]
    end
  end

  context "Edit a guide page" do
    setup do
      visit edition_path(@guide_edition)
      click_on "Add a new chapter"
    end

    should "push the correct values to the dataLayer when a form error is triggered on a Guide part page" do
      login_as_govuk_editor
      fill_in "Title", with: ""
      fill_in "Slug", with: ""
      click_button "Save"

      assert page.has_css?(".gem-c-error-summary")

      event_data = get_event_data

      assert_equal "error", event_data[0]["action"]
      assert_equal "form_error", event_data[0]["event_name"]
      assert_equal "Edit edition", event_data[0]["type"]
      assert_equal "Enter a title", event_data[0]["text"]
      assert_equal "Title", event_data[0]["section"]
      assert_equal "Guide", event_data[0]["tool_name"]

      assert_equal "error", event_data[1]["action"]
      assert_equal "form_error", event_data[1]["event_name"]
      assert_equal "Edit edition", event_data[1]["type"]
      assert_equal "Enter a slug", event_data[1]["text"]
      assert_equal "Slug", event_data[1]["section"]
      assert_equal "Guide", event_data[1]["tool_name"]
    end
  end

  context "Edit assignee page" do
    setup do
      visit edit_assignee_edition_path(@assigned_edition)
      disable_form_submit
    end

    should "push the correct values to the dataLayer when users are assigned to an edition" do
      find("label", text: "None").click
      click_button "Save"
      find("label", text: "Author").click
      click_button "Save"

      event_data = get_event_data

      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Choose a person to assign", event_data[0]["section"]
      assert_equal "None", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "1", event_data[0]["index"]["index_section_count"]

      assert_equal "Save", event_data[1]["action"]
      assert_equal "form_response", event_data[1]["event_name"]
      assert_equal "Assign person", event_data[1]["section"]
      assert_equal "{\"Choose a person to assign\":\"None\"}", event_data[1]["text"]
      assert_equal "Answer", event_data[1]["tool_name"]
      assert_equal "edit", event_data[1]["type"]

      assert_equal "select", event_data[2]["action"]
      assert_equal "select_content", event_data[2]["event_name"]
      assert_equal "Choose a person to assign", event_data[2]["section"]
      assert_equal "[REDACTED]", event_data[2]["text"]
      assert_equal "1", event_data[2]["index"]["index_section"]
      assert_equal "1", event_data[2]["index"]["index_section_count"]

      assert_equal "Save", event_data[3]["action"]
      assert_equal "form_response", event_data[3]["event_name"]
      assert_equal "Assign person", event_data[3]["section"]
      assert_equal "{\"Choose a person to assign\":\"[REDACTED]\"}", event_data[3]["text"]
      assert_equal "Answer", event_data[3]["tool_name"]
      assert_equal "edit", event_data[3]["type"]
    end
  end

  context "Assign 21 reviewer page" do
    setup do
      visit edit_reviewer_edition_path(@in_review_edition)
      disable_form_submit
    end

    should "push the correct values to the dataLayer when users are assigned as a 2i reviewer" do
      find("label", text: "None").click
      click_button "Save"
      find("label", text: "Author").click
      click_button "Save"

      event_data = get_event_data

      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Choose a person to assign", event_data[0]["section"]
      assert_equal "None", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "1", event_data[0]["index"]["index_section_count"]

      assert_equal "Save", event_data[1]["action"]
      assert_equal "form_response", event_data[1]["event_name"]
      assert_equal "Assign 2i reviewer", event_data[1]["section"]
      assert_equal "{\"Choose a person to assign\":\"None\"}", event_data[1]["text"]
      assert_equal "Answer", event_data[1]["tool_name"]
      assert_equal "edit", event_data[1]["type"]

      assert_equal "select", event_data[2]["action"]
      assert_equal "select_content", event_data[2]["event_name"]
      assert_equal "Choose a person to assign", event_data[2]["section"]
      assert_equal "[REDACTED]", event_data[2]["text"]
      assert_equal "1", event_data[2]["index"]["index_section"]
      assert_equal "1", event_data[2]["index"]["index_section_count"]

      assert_equal "Save", event_data[3]["action"]
      assert_equal "form_response", event_data[3]["event_name"]
      assert_equal "Assign 2i reviewer", event_data[3]["section"]
      assert_equal "{\"Choose a person to assign\":\"[REDACTED]\"}", event_data[3]["text"]
      assert_equal "Answer", event_data[3]["tool_name"]
      assert_equal "edit", event_data[3]["type"]
    end
  end

  context "Send to 2i page" do
    should "push the correct values to the dataLayer when events are triggered" do
      visit send_to_2i_page_edition_path(@edition)
      disable_form_submit
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

    should "push the correct flash message values to the dataLayer when the user navigates to the page without govuk_editor permission" do
      login_as(@user_no_permissions)
      visit send_to_2i_page_edition_path(@edition)

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "You do not have correct editor permissions for this action.", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer when the user has welsh_editor permission and the edition is not Welsh" do
      login_as_welsh_editor
      visit send_to_2i_page_edition_path(@edition)

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "You do not have correct editor permissions for this action.", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer when the form on success" do
      visit send_to_2i_page_edition_path(@edition)
      fill_in "Comment (optional)", with: "Some comment"
      click_button "Send to 2i"

      assert page.has_css?(".gem-c-success-alert")

      event_data = get_event_data

      assert_equal "success_alerts", event_data[0]["action"]
      assert_equal "flash_success", event_data[0]["event_name"]
      assert_equal "Sent to 2i", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer on a server error" do
      EditionProgressor.any_instance.expects(:progress).returns(false)

      visit send_to_2i_page_edition_path(@edition)
      fill_in "Comment (optional)", with: "Some comment"
      click_button "Send to 2i"

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "Due to a service problem, the request could not be made", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer when the user submits form without govuk_editor permission" do
      visit send_to_2i_page_edition_path(@edition)
      fill_in "Comment (optional)", with: "Some comment"
      login_as(@user_no_permissions)
      click_button "Send to 2i"

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "You do not have correct editor permissions for this action.", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer when the edition is not in a valid state to be sent to 2i" do
      visit send_to_2i_page_edition_path(@ready_edition)
      fill_in "Comment (optional)", with: "Some comment"
      click_button "Send to 2i"

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "Edition is not in a state where it can be sent to 2i", event_data[0]["text"]
    end
  end

  context "Skip review page" do
    should "push the correct values to the dataLayer when events are triggered" do
      login_as(@other)
      visit skip_review_page_edition_path(@edition)
      disable_form_submit
      fill_in "Comment (optional)", with: "Comment on skipping review"
      click_button "Skip review"

      event_data = get_event_data

      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Comment (optional)", event_data[0]["section"]
      assert_equal "26", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "1", event_data[0]["index"]["index_section_count"]

      assert_equal "Save", event_data[1]["action"]
      assert_equal "form_response", event_data[1]["event_name"]
      assert_equal "Skip review", event_data[1]["section"]
      assert_equal "{\"Comment (optional)\":\"26\"}", event_data[1]["text"]
      assert_equal "Answer", event_data[1]["tool_name"]
      assert_equal "edit", event_data[1]["type"]
    end

    should "push the correct flash message values to the dataLayer when user does not have skip_review permission" do
      login_as(@user_no_permissions)
      visit skip_review_page_edition_path(@edition)

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "You do not have correct editor permissions for this action.", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer on success" do
      login_as(@requester)

      visit skip_review_page_edition_path(@in_review_edition)
      fill_in "Comment (optional)", with: "Comment on skipping review"
      click_button "Skip review"

      assert page.has_css?(".gem-c-success-alert")

      event_data = get_event_data

      assert_equal "success_alerts", event_data[0]["action"]
      assert_equal "flash_success", event_data[0]["event_name"]
      assert_equal "2i review skipped", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer when a server error occurs on submission" do
      EditionProgressor.any_instance.expects(:progress).returns(false)

      login_as(@requester)
      visit skip_review_page_edition_path(@in_review_edition)
      fill_in "Comment (optional)", with: "Comment on skipping review"
      click_button "Skip review"

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "Due to a service problem, the request could not be made", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer when edition is not in a valid state to skip review" do
      login_as(@requester)
      visit skip_review_page_edition_path(@edition)
      fill_in "Comment (optional)", with: "Comment on skipping review"
      click_button "Skip review"

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "Edition is not in a state where review can be skipped", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer when the user is not the requester" do
      login_as(@other)

      visit skip_review_page_edition_path(@in_review_edition)
      fill_in "Comment (optional)", with: "Comment on skipping review"
      click_button "Skip review"

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "Due to a service problem, the request could not be made", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer when the user user does not have 'skip_review' permission" do
      login_as(@other)
      visit skip_review_page_edition_path(@in_review_edition)
      fill_in "Comment (optional)", with: "Comment on skipping review"
      login_as(@author)

      click_button "Skip review"

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "You do not have correct editor permissions for this action.", event_data[0]["text"]
    end
  end

  context "Request amendments page" do
    should "push the correct values to the dataLayer when user visits page without govuk_editor permission" do
      login_as(@user_no_permissions)
      visit request_amendments_page_edition_path(@edition.id)

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "You do not have correct editor permissions for this action.", event_data[0]["text"]
    end

    should "push the correct values to the dataLayer when events are triggered" do
      visit request_amendments_page_edition_path(@edition.id)
      disable_form_submit
      fill_in "Amendment details (optional)", with: "Some amendment details"
      click_button "Request amendments"

      event_data = get_event_data

      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Amendment details (optional)", event_data[0]["section"]
      assert_equal "22", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "1", event_data[0]["index"]["index_section_count"]

      assert_equal "Save", event_data[1]["action"]
      assert_equal "form_response", event_data[1]["event_name"]
      assert_equal "Request amendments", event_data[1]["section"]
      assert_equal "{\"Amendment details (optional)\":\"22\"}", event_data[1]["text"]
      assert_equal "Answer", event_data[1]["tool_name"]
      assert_equal "edit", event_data[1]["type"]
    end

    should "push the correct values to the dataLayer when edition is not in a valid state to request amendments" do
      visit request_amendments_page_edition_path(@edition.id)
      click_button "Request amendments"

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "Edition is not in a state where amendments can be requested", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer when events are triggered" do
      visit request_amendments_page_edition_path(@in_review_edition.id)
      fill_in "Amendment details (optional)", with: "Some amendment details"
      click_button "Request amendments"

      assert page.has_css?(".gem-c-success-alert")

      event_data = get_event_data

      assert_equal "success_alerts", event_data[0]["action"]
      assert_equal "flash_success", event_data[0]["event_name"]
      assert_equal "Amendments requested", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer when a server error occurs" do
      EditionProgressor.any_instance.expects(:progress).returns(false)

      visit request_amendments_page_edition_path(@in_review_edition.id)
      fill_in "Amendment details (optional)", with: "Some amendment details"
      click_button "Request amendments"

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "Due to a service problem, the request could not be made", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer when user requests amendments without govuk_editor permission" do
      visit request_amendments_page_edition_path(@edition.id)
      fill_in "Amendment details (optional)", with: "Some amendment details"
      login_as(@user_no_permissions)
      click_button "Request amendments"

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "You do not have correct editor permissions for this action.", event_data[0]["text"]
    end
  end

  context "No changes needed page" do
    should "push the correct values to the dataLayer when events are triggered" do
      visit no_changes_needed_page_edition_path(@edition.id)
      disable_form_submit
      fill_in "Comment (optional)", with: "Some comment or other"
      click_button "Approve 2i"

      event_data = get_event_data

      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Comment (optional)", event_data[0]["section"]
      assert_equal "21", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "1", event_data[0]["index"]["index_section_count"]

      assert_equal "Save", event_data[1]["action"]
      assert_equal "form_response", event_data[1]["event_name"]
      assert_equal "No changes needed", event_data[1]["section"]
      assert_equal "{\"Comment (optional)\":\"21\"}", event_data[1]["text"]
      assert_equal "Answer", event_data[1]["tool_name"]
      assert_equal "edit", event_data[1]["type"]
    end

    should "push the correct flash message values to the dataLayer when user does not have govuk_editor permission" do
      login_as(@user_no_permissions)
      visit no_changes_needed_page_edition_path(@edition.id)

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "You do not have correct editor permissions for this action.", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer when user has welsh_editor permission and edition is not Welsh" do
      login_as_welsh_editor
      visit no_changes_needed_page_edition_path(@edition.id)

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "You do not have correct editor permissions for this action.", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer on success" do
      visit no_changes_needed_page_edition_path(@in_review_edition.id)
      fill_in "Comment (optional)", with: "Some comment or other"
      click_button "Approve 2i"

      assert page.has_css?(".gem-c-success-alert")

      event_data = get_event_data

      assert_equal "success_alerts", event_data[0]["action"]
      assert_equal "flash_success", event_data[0]["event_name"]
      assert_equal "2i approved", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer when a server error occurs" do
      EditionProgressor.any_instance.expects(:progress).returns(false)

      visit no_changes_needed_page_edition_path(@in_review_edition.id)
      fill_in "Comment (optional)", with: "Some comment or other"
      click_button "Approve 2i"

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "Due to a service problem, the request could not be made", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer when user submits without govuk_editor permission" do
      visit no_changes_needed_page_edition_path(@in_review_edition.id)
      fill_in "Comment (optional)", with: "Some comment or other"
      login_as(@user_no_permissions)
      click_button "Approve 2i"

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "You do not have correct editor permissions for this action.", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer when edition is not in a valid state to approve review" do
      visit no_changes_needed_page_edition_path(@edition.id)
      fill_in "Comment (optional)", with: "Some comment or other"
      click_button "Approve 2i"

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "Edition is not in a state where a review can be approved", event_data[0]["text"]
    end
  end

  context "Send to fact check page" do
    setup do
      stub_holidays_used_by_fact_check
      @edition.state = "ready"
      @edition.save!
    end

    should "push the correct values to the dataLayer when events are triggered" do
      visit send_to_fact_check_page_edition_path(@edition.id)
      disable_form_submit
      fill_in "Email addresses", with: "fact-checker-one@example.com"
      fill_in "Customised message", with: "Some message"
      click_button "Send to fact check"

      event_data = get_event_data

      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Email addresses", event_data[0]["section"]
      assert_equal "28", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "2", event_data[0]["index"]["index_section_count"]

      assert_equal "select", event_data[1]["action"]
      assert_equal "select_content", event_data[1]["event_name"]
      assert_equal "Customised message", event_data[1]["section"]
      assert_equal "12", event_data[1]["text"]
      assert_equal "2", event_data[1]["index"]["index_section"]
      assert_equal "2", event_data[1]["index"]["index_section_count"]

      assert_equal "Save", event_data[2]["action"]
      assert_equal "form_response", event_data[2]["event_name"]
      assert_equal "Send to fact check", event_data[2]["section"]
      assert_equal "{\"Email addresses\":\"28\",\"Customised message\":\"12\"}", event_data[2]["text"]
      assert_equal "Answer", event_data[2]["tool_name"]
      assert_equal "edit", event_data[2]["type"]
    end

    should "push the correct flash message values to the dataLayer when the user does not have govuk_editor permission" do
      login_as(@user_no_permissions)
      visit send_to_fact_check_page_edition_path(@edition.id)

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "You do not have correct editor permissions for this action.", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer when the user user has welsh_editor permission" do
      login_as_welsh_editor
      visit send_to_fact_check_page_edition_path(@edition.id)

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "You do not have correct editor permissions for this action.", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer when the edition is not in a valid state to be sent to fact check" do
      @edition.state = "draft"
      @edition.save!

      visit send_to_fact_check_page_edition_path(@edition.id)

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "Edition is not in a state where it can be sent to fact check", event_data[0]["text"]
    end
  end

  context "Resend fact check email page" do
    setup do
      stub_holidays_used_by_fact_check
      @edition.state = "fact_check"
      @edition.save!

      FactoryBot.create(
        :action,
        requester: @govuk_requester,
        request_type: Action::SEND_FACT_CHECK,
        edition: @edition,
        email_addresses: "fact-checker-one@example.com, fact-checker-two@example.com",
        customised_message: "The customised message",
      )
    end

    should "push the correct values to the dataLayer when events are triggered" do
      visit resend_fact_check_email_page_edition_path(@edition.id)
      disable_form_submit
      click_button "Resend fact check email"

      event_data = get_event_data

      assert_equal "Save", event_data[0]["action"]
      assert_equal "form_response", event_data[0]["event_name"]
      assert_equal "Resend fact check email", event_data[0]["section"]
      assert_equal "{}", event_data[0]["text"]
      assert_equal "Answer", event_data[0]["tool_name"]
      assert_equal "edit", event_data[0]["type"]
    end

    should "push the correct flash message values to the dataLayer when the user does not have govuk_editor permission" do
      login_as(@user_no_permissions)
      visit resend_fact_check_email_page_edition_path(@edition.id)

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "You do not have correct editor permissions for this action.", event_data[0]["text"]
    end
  end

  context "Schedule publication page" do
    setup do
      @edition.state = "ready"
      @edition.save!

      visit schedule_page_edition_path(@edition.id)

      disable_form_submit
    end

    should "push the correct values to the dataLayer when events are triggered" do
      fill_in "Comment (optional)", with: "A comment about scheduling"
      fill_in "Day", with: "1"
      fill_in "Month", with: "12"
      fill_in "Year", with: "2026"
      fill_in "Hour", with: "09"
      fill_in "Minute", with: "01"
      click_button "Schedule"

      event_data = get_event_data

      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Comment (optional)", event_data[0]["section"]
      assert_equal "26", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "3", event_data[0]["index"]["index_section_count"]

      assert_equal "select", event_data[1]["action"]
      assert_equal "select_content", event_data[1]["event_name"]
      assert_equal "Publication date", event_data[1]["section"]
      assert_equal "1/12/2026", event_data[1]["text"]
      assert_equal "2", event_data[1]["index"]["index_section"]
      assert_equal "3", event_data[1]["index"]["index_section_count"]

      assert_equal "select", event_data[2]["action"]
      assert_equal "select_content", event_data[2]["event_name"]
      assert_equal "Publication time", event_data[2]["section"]
      assert_equal "09/01", event_data[2]["text"]
      assert_equal "3", event_data[2]["index"]["index_section"]
      assert_equal "3", event_data[2]["index"]["index_section_count"]

      assert_equal "Save", event_data[3]["action"]
      assert_equal "form_response", event_data[3]["event_name"]
      assert_equal "Schedule publication", event_data[3]["section"]
      assert_equal "{\"Comment (optional)\":\"26\",\"Publication date - Day\":\"1\",\"Publication date - Month\":\"12\",\"Publication date - Year\":\"2026\",\"Publication time - Hour\":\"09\",\"Publication time - Minute\":\"01\"}", event_data[3]["text"]
      assert_equal "Answer", event_data[3]["tool_name"]
      assert_equal "edit", event_data[3]["type"]
    end
  end

  context "Cancel scheduled publication page" do
    setup do
      @edition.state = "scheduled_for_publishing"
      @edition.publish_at = Time.zone.now + 1.day
      @edition.save!

      visit cancel_scheduled_publishing_page_edition_path(@edition.id)

      disable_form_submit
    end

    should "push the correct values to the dataLayer when events are triggered" do
      fill_in "Comment (optional)", with: "A comment about cancelling the schedule"
      click_button "Cancel scheduled publishing"

      event_data = get_event_data

      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Comment (optional)", event_data[0]["section"]
      assert_equal "39", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "1", event_data[0]["index"]["index_section_count"]

      assert_equal "Save", event_data[1]["action"]
      assert_equal "form_response", event_data[1]["event_name"]
      assert_equal "Cancel scheduled publishing", event_data[1]["section"]
      assert_equal "{\"Comment (optional)\":\"39\"}", event_data[1]["text"]
      assert_equal "Answer", event_data[1]["tool_name"]
      assert_equal "edit", event_data[1]["type"]
    end
  end

  context "Send to publish page" do
    setup do
      visit send_to_publish_page_edition_path(@edition.id)

      disable_form_submit
    end

    should "push the correct values to the dataLayer when events are triggered" do
      fill_in "Comment (optional)", with: "A comment about sending to publish"
      click_button "Send to publish"

      event_data = get_event_data

      assert_equal "select", event_data[0]["action"]
      assert_equal "select_content", event_data[0]["event_name"]
      assert_equal "Comment (optional)", event_data[0]["section"]
      assert_equal "34", event_data[0]["text"]
      assert_equal "1", event_data[0]["index"]["index_section"]
      assert_equal "1", event_data[0]["index"]["index_section_count"]

      assert_equal "Save", event_data[1]["action"]
      assert_equal "form_response", event_data[1]["event_name"]
      assert_equal "Send to publish", event_data[1]["section"]
      assert_equal "{\"Comment (optional)\":\"34\"}", event_data[1]["text"]
      assert_equal "Answer", event_data[1]["tool_name"]
      assert_equal "edit", event_data[1]["type"]
    end
  end
end
