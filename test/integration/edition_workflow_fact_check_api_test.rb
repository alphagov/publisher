require "integration_test_helper"

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
      assert page.has_css?(".gem-c-hint", text: "You can enter multiple email addresses if you comma separate them as follows: fact-checker-one@example.com, fact-checker-two@example.com")
      assert page.has_button?("Send to fact check")
      assert page.has_link?("Cancel")
    end

    should "redirect to edit tab when Cancel button is pressed on Send to Fact check page" do
      click_link("Cancel")
      assert_current_path edition_path(@ready_edition.id)
    end

    should "redirect back to the edit tab on submit and show success message" do
      fill_in "Email addresses", with: "fact-checker-one@example.com"
      click_button "Send to fact check"

      assert_current_path edition_path(@ready_edition.id)
      assert page.has_text?("Sent to fact check")
    end

    should "display an error message if an email address is invalid" do
      fill_in "Email addresses", with: "fact-checker-one.com"
      click_button "Send to fact check"

      assert_current_path send_to_fact_check_edition_path(@ready_edition.id)
      assert page.has_text?("Enter email addresses")
    end
  end

  context "Send to Fact check page with unsuccessful post requests" do
    setup do
      stub_post_new_fact_check_request(success: false)
      @ready_edition = FactoryBot.create(:answer_edition, :ready)
      visit send_to_fact_check_page_edition_path(@ready_edition)
    end

    should "keep user inputs when there is an input error" do
      fill_in "Email addresses", with: "fact-checker-one.com"
      click_button "Send to fact check"

      assert_current_path send_to_fact_check_edition_path(@ready_edition.id)
      assert page.has_text?("Enter email addresses")
      assert page.has_css?("input[value='fact-checker-one.com']")
    end

    should "keep user inputs when there is an api error" do
      fill_in "Email addresses", with: "fact-checker-one@example.com"
      click_button "Send to fact check"

      assert_current_path send_to_fact_check_edition_path(@ready_edition.id)
      assert page.has_text?("Due to a service problem, the request could not be made")
      assert page.has_css?("input[value='fact-checker-one@example.com']")
    end
  end
end
