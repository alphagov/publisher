require "integration_test_helper"
require "gds_api/test_helpers/calendars"

class EditionWorkflowFactCheckApiTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    login_as(@govuk_editor)
    @test_strategy.switch!(:fact_check_manager_api, true)
    stub_holidays_used_by_fact_check
    stub_events_for_all_content_ids
    stub_users_from_signon_api
    UpdateWorker.stubs(:perform_async)
  end

  context "Send to Fact check page with successful post requests" do
    setup do
      stub_post_new_fact_check_request(success: true)
      @ready_edition = FactoryBot.create(:answer_edition, :ready)
      visit send_to_fact_check_page_edition_path(@ready_edition)
    end

    should "render the page" do
      assert page.has_text?(@ready_edition.title)
      assert page.has_text?("Send to fact check")
      assert page.has_text?("Email addresses")
      assert page.has_text?("Reason for change (optional)")
      assert page.has_text?("Zendesk number")
      assert page.has_css?(".gem-c-hint", text: "Separate multiple email addresses with a comma or semi-colon, followed by a space")
      assert page.has_css?(".gem-c-hint", text: "This is shown in the email sent to the department")
      assert page.has_css?(".gem-c-hint", text: "This defaults to 5 working days from today")
      assert page.has_css?(".govuk-input__prefix", text: "https://govuk.zendesk.com/tickets/")
      assert page.has_button?("Send to fact check")
      assert page.has_link?("Cancel")
    end

    should "pre-populate the deadline for 5 working days" do
      today = Date.parse("2017-04-28")
      stub_calendars_has_a_bank_holiday_on(Date.parse("2017-05-01"), in_division: "england-and-wales")

      Timecop.freeze(today) do
        visit send_to_fact_check_page_edition_path(@ready_edition)
        assert page.has_css?("input[value='8']")
        assert page.has_css?("input[value='5']")
        assert page.has_css?("input[value='2017']")
      end
    end

    should "redirect to edit tab when Cancel button is pressed on Send to Fact check page" do
      click_link("Cancel")
      assert_current_path edition_path(@ready_edition.id)
    end

    should "redirect back to the edit tab on submit and show success message with minimal inputs" do
      date = 1.day.from_now

      fill_in "Email addresses", with: "fact-checker-one@example.com"
      fill_in "Day", with: date.day
      fill_in "Month", with: date.month
      fill_in "Year", with: date.year
      click_button "Send to fact check"

      assert_current_path edition_path(@ready_edition.id)
      assert page.has_text?("Sent to fact check")
    end

    should "redirect back to the edit tab on submit and show success message with full inputs" do
      date = 1.day.from_now

      fill_in "Email addresses", with: "fact-checker-one@example.com"
      fill_in "Zendesk number", with: 1_234_567
      fill_in "Reason for change", with: "Reason"
      fill_in "Day", with: date.day
      fill_in "Month", with: date.month
      fill_in "Year", with: date.year
      click_button "Send to fact check"

      assert_current_path edition_path(@ready_edition.id)
      assert page.has_text?("Sent to fact check")
    end

    should "abort state change and display an error message if an email address is invalid" do
      date = 1.day.from_now

      fill_in "Email addresses", with: "fact-checker-one.com"
      fill_in "Zendesk number", with: 1_234_567
      fill_in "Reason for change", with: "Reason"
      fill_in "Day", with: date.day
      fill_in "Month", with: date.month
      fill_in "Year", with: date.year
      click_button "Send to fact check"
      @ready_edition.reload

      assert_current_path send_to_fact_check_edition_path(@ready_edition.id)
      assert_equal "ready", @ready_edition.state
      assert page.has_text?("Email addresses are invalid")
    end

    should "abort state change and display an error message if the deadline is invalid" do
      fill_in "Email addresses", with: "fact-checker-one@example.com"
      fill_in "Zendesk number", with: 1_234_567
      fill_in "Reason for change", with: "Reason"
      fill_in "Day", with: 999
      fill_in "Month", with: 999
      fill_in "Year", with: 999
      click_button "Send to fact check"
      @ready_edition.reload

      assert_current_path send_to_fact_check_edition_path(@ready_edition.id)
      assert_equal "ready", @ready_edition.state
      assert page.has_text?("Enter a deadline")
    end

    should "abort state change and display an error message if the zendesk number is invalid" do
      date = 1.day.from_now

      fill_in "Email addresses", with: "fact-checker-one@example.com"
      fill_in "Zendesk number", with: "notanumber"
      fill_in "Reason for change", with: "Reason"
      fill_in "Day", with: date.day
      fill_in "Month", with: date.month
      fill_in "Year", with: date.year
      click_button "Send to fact check"
      @ready_edition.reload

      assert_current_path send_to_fact_check_edition_path(@ready_edition.id)
      assert_equal "ready", @ready_edition.state
      assert page.has_text?("Zendesk number must be a number at least 7 digits long")
    end
  end

  context "Send to Fact check page with unsuccessful post requests" do
    setup do
      stub_post_new_fact_check_request(success: false)
      @ready_edition = FactoryBot.create(:answer_edition, :ready)
      visit send_to_fact_check_page_edition_path(@ready_edition)
    end

    should "keep user inputs when there is an input error" do
      date = 1.day.from_now

      fill_in "Email addresses", with: "fact-checker-one.com"
      fill_in "Zendesk number", with: 1_234_567
      fill_in "Reason for change", with: "A reason"
      fill_in "Day", with: date.day
      fill_in "Month", with: date.month
      fill_in "Year", with: date.year
      click_button "Send to fact check"

      assert_current_path send_to_fact_check_edition_path(@ready_edition.id)
      assert page.has_text?("Email addresses are invalid")
      assert page.has_css?("input[value='fact-checker-one.com']")
      assert page.has_css?("input[value='1234567']")
      assert page.has_css?("textarea", text: "A reason")
      assert page.has_css?("input[value='#{date.day}']")
      assert page.has_css?("input[value='#{date.month}']")
      assert page.has_css?("input[value='#{date.year}']")
    end

    should "keep user inputs when deadline is invalid type" do
      fill_in "Email addresses", with: "fact-checker-one@email.com"

      fill_in "Day", with: "not"
      fill_in "Month", with: "a"
      fill_in "Year", with: "number"
      click_button "Send to fact check"

      assert_current_path send_to_fact_check_edition_path(@ready_edition.id)
      assert page.has_text?("Enter a deadline")
      assert page.has_css?("input[value='fact-checker-one@email.com']")
      assert page.has_css?("input[value='not']")
      assert page.has_css?("input[value='a']")
      assert page.has_css?("input[value='number']")
    end

    should "keep user inputs when there is an api error" do
      date = 1.day.from_now

      fill_in "Email addresses", with: "fact-checker-one@example.com"
      fill_in "Zendesk number", with: 1_234_567
      fill_in "Reason for change", with: "A reason"
      fill_in "Day", with: date.day
      fill_in "Month", with: date.month
      fill_in "Year", with: date.year
      click_button "Send to fact check"

      assert_current_path send_to_fact_check_edition_path(@ready_edition.id)
      assert page.has_text?("Due to a service problem, the request could not be made")
      assert page.has_css?("input[value='fact-checker-one@example.com']")
      assert page.has_css?("input[value='1234567']")
      assert page.has_css?("textarea", text: "A reason")
      assert page.has_css?("input[value='#{date.day}']")
      assert page.has_css?("input[value='#{date.month}']")
      assert page.has_css?("input[value='#{date.year}']")
    end

    should "log the error" do
      Rails.logger.expects(:error).with("API Error Response for Edition id #{@ready_edition.id}: GdsApi::HTTPErrorResponse Example error message")
      date = 1.day.from_now

      fill_in "Email addresses", with: "fact-checker-one@example.com"
      fill_in "Zendesk number", with: 1_234_567
      fill_in "Reason for change", with: "A reason"
      fill_in "Day", with: date.day
      fill_in "Month", with: date.month
      fill_in "Year", with: date.year
      click_button "Send to fact check"
    end
  end

  context "Resend fact check email page with successful post requests" do
    setup do
      stub_post_resend_fact_check_emails(success: true)
      @fact_check_edition = FactoryBot.create(:edition, :fact_check)
      visit resend_fact_check_email_page_edition_path(@fact_check_edition)
    end

    should "render the page" do
      assert page.has_text?(@fact_check_edition.title)
      assert page.has_text?("Resend fact check email")
      assert page.has_text?("Email addresses")
      assert page.has_button?("Resend fact check email")
      assert page.has_link?("Cancel")
    end

    should "redirect to edit tab when Cancel link is clicked" do
      click_link("Cancel")
      assert_current_path edition_path(@fact_check_edition.id)
    end

    should "redirect back to the edit tab on submit and show success message" do
      click_button "Resend fact check email"

      assert_current_path edition_path(@fact_check_edition.id)
      assert page.has_text?("Fact check email re-sent")
    end
  end

  context "Resend fact check email page with unsuccessful post requests" do
    setup do
      stub_post_resend_fact_check_emails(success: false)
      @fact_check_edition = FactoryBot.create(:edition, :fact_check)
      visit resend_fact_check_email_page_edition_path(@fact_check_edition)
    end

    should "re-render the page with an error message upon submit" do
      click_button "Resend fact check email"

      assert_current_path resend_fact_check_email_edition_path(@fact_check_edition)
      assert page.has_text?("Due to a service problem, the request could not be made")
      assert page.has_text?(@fact_check_edition.title)
      assert page.has_text?("Resend fact check email")
      assert page.has_text?("Email addresses")
      assert page.has_button?("Resend fact check email")
      assert page.has_link?("Cancel")
    end

    should "log the error" do
      Rails.logger.expects(:error).with("API Error Response for Edition #{@fact_check_edition.id}: GdsApi::HTTPErrorResponse Example error message")
      click_button "Resend fact check email"
    end
  end

  context "Update Fact check page with successful post requests" do
    setup do
      @fact_check_edition = FactoryBot.create(:edition, :fact_check)
      visit edition_path(@fact_check_edition)
      stub_patch_update_fact_check_content(success: true, source_id: @fact_check_edition.id)
    end

    should "display a success message and update the edition" do
      fill_in "Body", with: "some new content"
      click_button "Save"
      @fact_check_edition.reload

      assert page.has_text?("Edition updated successfully.")
      assert page.has_text?("Fact check request updated.")
      assert_equal "some new content", @fact_check_edition.body
    end

    should "display an error but still save the page when fact check request form fails" do
      errors_stub = Minitest::Mock.new
      def errors_stub.full_messages = ["Invalid data!"]
      FactCheckRequestForm.any_instance.stubs(:valid?).with(:update).returns(false)
      FactCheckRequestForm.any_instance.stubs(:errors).returns(errors_stub)
      Rails.logger.expects(:error).with("Request form validation errors: Invalid data!")

      fill_in "Body", with: "some new content"
      click_button "Save"
      @fact_check_edition.reload

      assert page.has_text?("Due to a service problem, the fact check request could not be updated. The edition was successfully saved")
      assert_equal "some new content", @fact_check_edition.body
    end
  end

  context "Update Fact check page with unsuccessful post requests" do
    setup do
      @fact_check_edition = FactoryBot.create(:edition, :fact_check)
      visit edition_path(@fact_check_edition)
      stub_patch_update_fact_check_content(success: false, source_id: @fact_check_edition.id)
    end

    should "display and log an error but still save the edition" do
      Rails.logger.expects(:error).with("API Error Response for Edition id #{@fact_check_edition.id}: GdsApi::HTTPErrorResponse Example error message")

      fill_in "Body", with: "some new content"
      click_button "Save"
      @fact_check_edition.reload

      assert page.has_text?("Due to a service problem, the fact check request could not be updated. The edition was successfully saved")
      assert_equal "some new content", @fact_check_edition.body
    end
  end
end
