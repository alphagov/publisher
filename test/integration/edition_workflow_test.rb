require "integration_test_helper"

class EditionWorkflowTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    @govuk_requester = FactoryBot.create(:user, :govuk_editor, name: "Stub requester")
    login_as(@govuk_editor)
    stub_holidays_used_by_fact_check
    stub_events_for_all_content_ids
    stub_users_from_signon_api
    UpdateWorker.stubs(:perform_async)
  end

  context "unpublish tab" do
    context "user does not have required permissions" do
      should "not show unpublish tab when user is not govuk editor" do
        login_as(FactoryBot.create(:user, name: "Stub User"))
        draft_edition = FactoryBot.create(:edition, :draft)

        visit edition_path(draft_edition)

        assert page.has_no_text?("Unpublish")
      end
    end

    context "user has required permissions" do
      context "when state is 'published'" do
        setup do
          @published_edition = FactoryBot.create(:edition, :published)
          visit edition_path(@published_edition)
          click_link("Unpublish")
        end

        should "show 'Unpublish' header and 'Continue' button" do
          within :css, ".gem-c-heading h2" do
            assert page.has_text?("Unpublish")
          end
          assert page.has_button?("Continue")
        end

        should "show 'cannot be undone' banner" do
          assert page.has_text?("If you unpublish a page from GOV.UK it cannot be undone.")
        end

        should "show 'Redirect to URL' text, input box and example text" do
          assert page.has_text?("Redirect to URL")
          assert page.has_text?("For example: https://www.gov.uk/redirect-to-replacement-page")
          assert page.has_css?(".govuk-input", count: 1)
        end

        should "navigate to 'confirm-unpublish' page when 'Continue' button is clicked" do
          click_button("Continue")
          assert_equal(page.current_path, "/editions/#{@published_edition.id}/unpublish/confirm-unpublish")
        end
      end

      context "when state is not 'published'" do
        should "not show unpublish tab" do
          draft_edition = FactoryBot.create(:edition, :draft)
          visit edition_path(draft_edition)

          assert page.has_no_text?("Unpublish")
        end
      end
    end
  end

  context "Schedule page" do
    setup do
      @ready_edition = FactoryBot.create(:answer_edition, :ready)
      visit schedule_page_edition_path(@ready_edition.id)
    end

    should "render the 'Schedule' page" do
      within :css, ".gem-c-heading" do
        assert page.has_css?("h1", text: "Schedule publication")
        assert page.has_css?(".gem-c-heading__context", text: @ready_edition.title)
      end

      within :css, ".gem-c-textarea" do
        assert page.has_css?("label", text: "Comment (optional)")
        assert page.has_css?("textarea")
      end

      within all(".govuk-fieldset")[0] do
        assert page.has_css?("legend", text: "Publication date")
        assert page.has_css?(".govuk-label", text: "Day")
        assert page.has_css?("input[name='publish_at_3i']")
        assert page.has_css?(".govuk-label", text: "Month")
        assert page.has_css?("input[name='publish_at_2i']")
        assert page.has_css?(".govuk-label", text: "Year")
        assert page.has_css?("input[name='publish_at_1i']")
      end

      within all(".govuk-fieldset")[1] do
        assert page.has_css?("legend", text: "Publication time")
        assert page.has_css?(".govuk-label", text: "Hour")
        assert page.has_css?("input[name='publish_at_4i'][value='00']")
        assert page.has_css?(".govuk-label", text: "Minute")
        assert page.has_css?("input[name='publish_at_5i'][value='01']")
      end

      assert page.has_button?("Schedule")
      assert page.has_link?("Cancel")
    end

    should "generate a date hint test 3 months in the future" do
      travel_to Time.zone.local(2025, 10, 1, 0, 0, 0)
      visit schedule_page_edition_path(@ready_edition.id)

      assert page.has_css?(".govuk-hint", text: "For example, 1 1 2026")
    end

    should "redirect to edit tab when Cancel button is pressed on Send to 2i page" do
      click_link("Cancel")
      assert_current_path edition_path(@ready_edition.id)
    end

    should "show success message and redirect back to the edit tab on submit" do
      date = 1.day.from_now

      fill_in "Day", with: date.day
      fill_in "Month", with: date.month
      fill_in "Year", with: date.year
      fill_in "Hour", with: date.hour
      fill_in "Minute", with: date.min
      click_button "Schedule"

      assert_current_path edition_path(@ready_edition.id)
      assert page.has_text?("Scheduled to publish at #{date.to_fs(:govuk_date)}")
    end
  end

  context "Resend fact check email page" do
    should "render the 'Resend fact check email' page" do
      fact_check_edition = FactoryBot.create(:edition, :fact_check)
      FactoryBot.create(
        :action,
        requester: @govuk_editor,
        request_type: Action::SEND_FACT_CHECK,
        edition: fact_check_edition,
        email_addresses: "fact-checker-one@example.com, fact-checker-two@example.com",
        customised_message: "The customised message",
      )

      visit resend_fact_check_email_page_edition_path(fact_check_edition)

      assert page.has_content?(fact_check_edition.title)
      assert page.has_content?("Resend fact check email")
      assert page.has_content?("Email addresses")
      assert page.has_content?("fact-checker-one@example.com, fact-checker-two@example.com")
      assert page.has_content?("Customised message")
      assert page.has_content?("The customised message")
      assert page.has_button?("Resend fact check email")
      assert page.has_link?("Cancel")
    end
  end

  context "Request amendments page" do
    setup do
      @in_review_edition = FactoryBot.create(:edition, :in_review)
      visit request_amendments_page_edition_path(@in_review_edition)
    end

    should "save comment to edition history" do
      fill_in "Amendment details (optional)", with: "Please make these changes"
      click_on "Request amendments"
      click_on "History and notes"

      assert page.has_content?("Request amendments by")
      assert page.has_content?("Please make these changes")
    end

    should "show success message and redirect back to the edit tab on submit" do
      click_on "Request amendments"

      assert_current_path edition_path(@in_review_edition.id)
      assert page.has_text?("Amendments requested")
    end

    context "current user is also the requester" do
      should "populate comment box with submitted comment when there is an error" do
        login_as(@in_review_edition.latest_status_action.requester)

        visit request_amendments_page_edition_path(@in_review_edition)
        fill_in "Amendment details (optional)", with: "Please make these changes"
        click_on "Request amendments"

        assert page.has_content?("Due to a service problem, the request could not be made")
        assert page.has_content?("Please make these changes")
      end
    end
  end

  context "No changes needed page" do
    setup do
      @in_review_edition = FactoryBot.create(:edition, :in_review)
    end

    should "save comment to edition history" do
      visit no_changes_needed_page_edition_path(@in_review_edition)
      fill_in "Comment (optional)", with: "Looks great"
      click_on "Approve 2i"
      click_on "History and notes"

      assert page.has_content?("Approve review by")
      assert page.has_content?("Looks great")
    end

    should "show success message and redirect back to the edit tab on submit" do
      visit no_changes_needed_page_edition_path(@in_review_edition)
      click_button "Approve 2i"

      assert_current_path edition_path(@in_review_edition.id)
      assert page.has_text?("2i approved")
    end

    context "current user is also the requester" do
      should "populate comment box with submitted comment when there is an error" do
        login_as(@in_review_edition.latest_status_action.requester)

        visit no_changes_needed_page_edition_path(@in_review_edition)
        fill_in "Comment (optional)", with: "Great job!"
        click_on "Approve 2i"

        assert page.has_content?("Due to a service problem, the request could not be made")
        assert page.has_content?("Great job!")
      end
    end
  end

  context "Approve fact check page" do
    setup do
      @fact_check_received_edition = FactoryBot.create(:edition, :fact_check_received, title: "Edit page title")
    end

    should "save comment to edition history" do
      FactoryBot.create(
        :action,
        requester: @govuk_editor,
        request_type: Action::SEND_FACT_CHECK,
        edition: @fact_check_received_edition,
        email_addresses: "fact-checker-one@example.com, fact-checker-two@example.com",
        customised_message: "The customised message",
      )

      visit approve_fact_check_page_edition_path(@fact_check_received_edition)
      fill_in "Comment (optional)", with: "Looks great"
      click_on "Approve fact check"
      click_on "History and notes"

      assert page.has_content?("Approve fact check by")
      assert page.has_content?("Looks great")
    end

    should "show success message and redirect back to the edit tab on submit" do
      visit approve_fact_check_page_edition_path(@fact_check_received_edition)
      click_button "Approve fact check"

      assert_current_path edition_path(@fact_check_received_edition.id)
      assert page.has_text?("Fact check approved")
    end

    context "current user is also the requester" do
      setup do
        login_as(@govuk_requester)
      end

      should "populate comment box with submitted comment when there is an error" do
        visit approve_fact_check_page_edition_path(@fact_check_received_edition)

        @fact_check_received_edition.state = "ready"
        @fact_check_received_edition.save!

        fill_in "Comment (optional)", with: "Great job!"
        click_on "Approve fact check"

        assert page.has_content?("Edition is not in a state where fact check can be approved")
        assert page.has_content?("Great job!")
      end
    end
  end

  context "Skip review page" do
    context "current user may skip review" do
      setup do
        login_as(@govuk_requester)
        @govuk_requester.permissions << "skip_review"
        @in_review_edition = FactoryBot.create(:edition, :in_review, requester: @govuk_requester)
        visit skip_review_page_edition_path(@in_review_edition)
      end

      should "render the 'Skip review' page" do
        assert page.has_content?("Skip review")
        assert page.has_content?(@in_review_edition.title)
        assert page.has_content?("You should only skip review in exceptional circumstances")
        assert page.has_content?("Comment (optional)")
        assert page.has_button?("Skip review")
        assert page.has_link?("Cancel")
      end

      should "save comment to edition history" do
        fill_in "Comment (optional)", with: "Looks great"
        click_on "Skip review"
        click_on "History and notes"

        assert page.has_content?("Skip review by Stub requester")
        assert page.has_content?("Looks great")
      end

      should "show success message and redirect back to the edit tab on submit" do
        click_button "Skip review"

        assert_current_path edition_path(@in_review_edition.id)
        assert page.has_text?("2i review skipped")
      end
    end

    context "current user is not the requester" do
      setup do
        @govuk_editor.permissions << "skip_review"
      end

      should "populate comment box with submitted comment when there is an error" do
        @in_review_edition = FactoryBot.create(:edition, :in_review)

        visit skip_review_page_edition_path(@in_review_edition)
        fill_in "Comment (optional)", with: "No review required"
        click_on "Skip review"

        assert page.has_content?("Due to a service problem, the request could not be made")
        assert page.has_content?("No review required")
      end
    end
  end

  context "Send to 2i page" do
    setup do
      @draft_edition = FactoryBot.create(:edition, :draft)
      visit send_to_2i_page_edition_path(@draft_edition)
    end

    should "render the 'Send to 2i' page" do
      within :css, ".gem-c-heading" do
        assert page.has_css?("h1", text: "Send to 2i")
        assert page.has_css?(".gem-c-heading__context", text: @draft_edition.title)
      end

      assert page.has_text?("Explain what changes you did or did not make and why. Include a link to the relevant Zendesk ticket and Jira card. If you’ve added a change note already, you do not need to add another one.")
      assert page.has_link?("Read guidance on writing good change notes (opens in new tab)", href: "https://gov-uk.atlassian.net/l/cp/dwn06raQ")

      within :css, ".gem-c-textarea" do
        assert page.has_css?("textarea")
      end

      assert page.has_button?("Send to 2i")
      assert page.has_link?("Cancel")
    end

    should "redirect to edit tab when Cancel button is pressed on Send to 2i page" do
      click_link("Cancel")
      assert_current_path edition_path(@draft_edition.id)
    end

    should "show success message and redirect back to the edit tab on submit" do
      click_button "Send to 2i"

      assert_current_path edition_path(@draft_edition.id)
      assert page.has_text?("Sent to 2i")
    end
  end

  context "Send to Fact check page" do
    setup do
      @ready_edition = FactoryBot.create(:answer_edition, :ready)
      visit send_to_fact_check_page_edition_path(@ready_edition)
    end

    should "render the page" do
      assert page.has_text?(@ready_edition.title)
      assert page.has_text?("Send to fact check")
      assert page.has_text?("Email addresses")
      assert page.has_css?(".gem-c-hint", text: "You can enter multiple email addresses if you comma separate them as follows: fact-checker-one@example.com, fact-checker-two@example.com")
      assert page.has_text?("Customised message")
      assert page.has_text?("The GOV.UK Content Team made the changes because")
      assert page.has_button?("Send to fact check")
      assert page.has_link?("Cancel")
    end

    should "redirect to edit tab when Cancel button is pressed on Send to Fact check page" do
      click_link("Cancel")
      assert_current_path edition_path(@ready_edition.id)
    end

    should "redirect back to the edit tab on submit and show success message" do
      fill_in "Email addresses", with: "fact-checker-one@example.com"
      fill_in "Customised message", with: "Please check this"
      click_button "Send to fact check"

      assert_current_path edition_path(@ready_edition.id)
      assert page.has_text?("Sent to fact check")
    end

    should "redirect back to the edit tab and show success message when pre-filled customised message is used" do
      assert page.has_text?("The GOV.UK Content Team made the changes because")

      fill_in "Email addresses", with: "fact-checker-one@example.com"
      click_button "Send to fact check"

      assert_current_path edition_path(@ready_edition.id)
      assert page.has_text?("Sent to fact check")
    end

    should "display an error message if an email address is invalid" do
      fill_in "Email addresses", with: "fact-checker-one.com"
      fill_in "Customised message", with: "Please check this"
      click_button "Send to fact check"

      assert_current_path send_to_fact_check_edition_path(@ready_edition.id)
      assert page.has_text?("Enter email addresses and/or customised message")
    end

    should "display an error message if customised message is empty" do
      fill_in "Email addresses", with: "fact-checker-one@example.com"
      fill_in "Customised message", with: ""
      click_button "Send to fact check"

      assert_current_path send_to_fact_check_edition_path(@ready_edition.id)
      assert page.has_text?("Enter email addresses and/or customised message")
    end

    should "keep user inputs when there is an error" do
      fill_in "Email addresses", with: "fact-checker-one.com"
      fill_in "Customised message", with: "Please check this"
      click_button "Send to fact check"

      assert_current_path send_to_fact_check_edition_path(@ready_edition.id)
      assert page.has_text?("Enter email addresses and/or customised message")
      assert page.has_css?("input[value='fact-checker-one.com']")
      assert page.has_text?("Please check this")
    end
  end

  context "Send to publish page" do
    should "save comment to edition history" do
      scheduled_for_publishing_edition = FactoryBot.create(:edition, :scheduled_for_publishing)

      visit send_to_publish_page_edition_path(scheduled_for_publishing_edition)
      fill_in "Comment (optional)", with: "Looks great"
      click_on "Send to publish"
      click_on "History and notes"

      assert page.has_content?("Publish by")
      assert page.has_content?("Looks great")
    end

    should "populate comment box with submitted comment when there is an error" do
      draft_edition = FactoryBot.create(:edition, :draft)

      visit send_to_publish_page_edition_path(draft_edition)
      fill_in "Comment (optional)", with: "Publish a go-go!"
      click_on "Send to publish"

      assert page.has_content?("Edition is not in a state where it can be published")
      assert page.has_content?("Publish a go-go")
    end

    should "show an error when the edition is not in a state that can be published from" do
      draft_edition = FactoryBot.create(:edition, :draft)

      visit send_to_publish_page_edition_path(draft_edition)
      click_on "Send to publish"

      assert page.has_content?("Edition is not in a state where it can be published")
    end
  end

  context "Cancel scheduled publishing page" do
    should "save comment to edition history" do
      scheduled_for_publishing_edition = FactoryBot.create(:edition, :scheduled_for_publishing)

      visit cancel_scheduled_publishing_page_edition_path(scheduled_for_publishing_edition)
      fill_in "Comment (optional)", with: "Looks great"
      click_on "Cancel scheduled publishing"
      click_on "History and notes"

      assert page.has_content?("Cancel scheduled publishing by")
      assert page.has_content?("Looks great")
    end

    should "populate comment box with submitted comment when there is an error" do
      draft_edition = FactoryBot.create(:edition, :draft)

      visit cancel_scheduled_publishing_page_edition_path(draft_edition)
      fill_in "Comment (optional)", with: "Forget about it"
      click_on "Cancel scheduled publishing"

      assert page.has_content?("Edition is not in a state where scheduling can be cancelled")
      assert page.has_content?("Forget about it")
    end
  end
end
