require "integration_test_helper"

class EditionHistoryTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    login_as(@govuk_editor)
    stub_events_for_all_content_ids
    stub_users_from_signon_api
    UpdateWorker.stubs(:perform_async)
  end

  context "History and notes tab" do
    setup do
      @draft_edition = FactoryBot.create(:edition, :draft)
      visit edition_path(@draft_edition)
      click_link("History and notes")
    end

    should "show a heading" do
      assert page.has_css?("h2", text: "History and notes")
    end

    should "show inset text" do
      within :css, ".gem-c-inset-text" do
        assert page.has_text?("Send fact check responses to #{@draft_edition.fact_check_email_address} and include [#{@draft_edition.id}] in the subject line.")
      end
    end

    should "show an 'Add edition note' button" do
      assert page.has_link?("Add edition note")
    end

    should "navigate to the 'Add edition note' page when the button is clicked" do
      click_link("Add edition note")
      assert_current_path history_add_edition_note_edition_path(@draft_edition.id)
    end

    should "display the accordion section headers" do
      assert page.has_css?(".govuk-accordion__section-header h2", text: "Edition 1")
    end

    should "show an 'Update important note' button" do
      assert page.has_link?("Update important note")
    end

    should "navigate to the 'Update important note' page when the button is clicked" do
      click_link("Update important note")
      assert_current_path history_update_important_note_edition_path(@draft_edition.id)
    end

    context "show a Preview or a view on GOV.UK link" do
      should "show a Preview button when the edition is draft" do
        assert page.has_link?("Preview (opens in new tab)")
      end

      should "show a Preview button when the edition is in review" do
        in_review_edition = FactoryBot.create(:edition, :in_review)
        visit edition_path(in_review_edition)
        click_link("History and notes")

        assert page.has_link?("Preview (opens in new tab)")
      end

      should "show a Preview button when the edition is out for fact check" do
        fact_check_edition = FactoryBot.create(:edition, :fact_check)
        visit edition_path(fact_check_edition)
        click_link("History and notes")

        assert page.has_link?("Preview (opens in new tab)")
      end

      should "show a Preview button when the edition is ready" do
        ready_edition = FactoryBot.create(:answer_edition, :ready)
        visit edition_path(ready_edition)
        click_link("History and notes")

        assert page.has_link?("Preview (opens in new tab)")
      end

      should "show a Preview button when the edition is scheduled for publishing" do
        scheduled_for_publishing_edition = FactoryBot.create(:edition, :scheduled_for_publishing)
        visit edition_path(scheduled_for_publishing_edition)
        click_link("History and notes")

        assert page.has_link?("Preview (opens in new tab)")
      end

      should "show a View on GOV.UK button when the edition is published" do
        published_edition = FactoryBot.create(:edition, :published)
        visit edition_path(published_edition)
        click_link("History and notes")

        assert page.has_link?("View on GOV.UK (opens in new tab)")
      end

      should "show a View on GOV.UK button when the edition is archived" do
        archived_edition = FactoryBot.create(:edition, :archived)
        visit edition_path(archived_edition)
        click_link("History and notes")

        assert page.has_link?("View on GOV.UK (opens in new tab)")
      end

      should "still show the conditional preview/view link when the user does not have editor permissions" do
        stub_user = FactoryBot.create(:user, name: "Stub user")
        login_as(stub_user)

        visit edition_path(@draft_edition)
        click_link("History and notes")

        assert page.has_link?("Preview (opens in new tab)")
      end
    end

    context "when the user has no permissions" do
      should "hide the note action buttons from the user" do
        user = FactoryBot.create(:user, name: "Stub User")
        login_as(user)

        visit edition_path(@draft_edition)
        click_link("History and notes")

        assert_not user.has_editor_permissions?(@draft_edition)
        assert_not page.has_content?("Add edition note")
        assert_not page.has_content?("Update important note")
      end
    end

    context "when the user has welsh editor permissions" do
      setup do
        @user = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
        @user_welsh = FactoryBot.create(:user, :welsh_editor, name: "Stub User")
        login_as(@user)
      end

      should "hide the note action buttons from the user on a non welsh document" do
        visit edition_path(@draft_edition)
        login_as(@user_welsh)

        click_link("History and notes")

        assert_not @user_welsh.has_editor_permissions?(@draft_edition)
        assert_not page.has_content?("Add edition note")
        assert_not page.has_content?("Update important note")
      end

      should "show the note action buttons for the user on a welsh document" do
        edition = @user.create_edition(:answer, panopticon_id: FactoryBot.create(:artefact, language: "cy").id, title: "My Title", slug: "my-title")
        edition.state = "fact_check"
        edition.save!
        login_as(@user_welsh)

        visit edition_path(edition)
        click_link("History and notes")

        assert @user_welsh.has_editor_permissions?(edition)
        assert page.has_content?("Add edition note")
        assert page.has_content?("Update important note")
      end
    end

    context "Edition displays the correct data for actions" do
      setup do
        @edition = FactoryBot.create(:edition, created_at: "2024-01-23")
      end

      should "display 'Assign' action" do
        user = FactoryBot.create(:user, name: "Steve Ogrizovic")
        @edition.actions.create! request_type: Action::ASSIGN, requester_id: user.id, created_at: "2024-02-24 15:41:00", comment: "Assigned to me"

        visit edition_path(@edition)
        click_link("History and notes")

        within :css, ".history__action--assign__heading" do
          assert page.has_css?("time", text: "3:41pm, 24 February 2024")
          assert page.has_text?("Assign by Steve Ogrizovic")
        end

        within :css, ".history__action--assign__content" do
          assert page.has_text?("Assigned to me")
        end
      end

      should "display 'Note' action" do
        user = FactoryBot.create(:user, name: "David Phillips")
        @edition.actions.create! request_type: Action::NOTE, requester_id: user.id, created_at: "2024-03-01 10:30:00", comment: "This is a note"

        visit edition_path(@edition)
        click_link("History and notes")

        within :css, ".history__action--note__heading" do
          assert page.has_css?("time", text: "10:30am, 1 March 2024")
          assert page.has_text?("Note by David Phillips")
        end

        within :css, ".history__action--note__content" do
          assert page.has_text?("This is a note")
        end
      end

      should "display 'Request review' action" do
        user = FactoryBot.create(:user, name: "Greg Downs")
        @edition.actions.create! request_type: Action::REQUEST_REVIEW, requester_id: user.id, created_at: "2024-04-02 17:23:00", comment: "Requesting review"

        visit edition_path(@edition)
        click_link("History and notes")

        within :css, ".history__action--request_review__heading" do
          assert page.has_css?("time", text: "5:23pm, 2 April 2024")
          assert page.has_text?("Request review by Greg Downs")
        end

        within :css, ".history__action--request_review__content" do
          assert page.has_text?("Requesting review")
        end
      end

      should "display 'Send fact check' action" do
        user = FactoryBot.create(:user, name: "Lloyd McGrath")
        @edition.actions.create! request_type: Action::SEND_FACT_CHECK, requester_id: user.id, created_at: "2024-05-16 18:12:00", comment: "Fact check requested"

        visit edition_path(@edition)
        click_link("History and notes")

        within :css, ".history__action--send_fact_check__heading" do
          assert page.has_css?("time", text: "6:12pm, 16 May 2024")
          assert page.has_text?("Send fact check by Lloyd McGrath")
        end

        within :css, ".history__action--send_fact_check__content" do
          assert page.has_text?("Fact check requested")
        end
      end

      should "display 'Receive fact check' action" do
        @edition.actions.create! request_type: Action::RECEIVE_FACT_CHECK, created_at: "2024-06-06 8:32:00", comment: "We’re happy for you to publish. -----Original Message----- Reply and confirm the content is correct.", comment_sanitized: true

        visit edition_path(@edition)
        click_link("History and notes")

        within :css, ".history__action--receive_fact_check__heading" do
          assert page.has_css?("time", text: "8:32am, 6 June 2024")
          assert page.has_text?("Receive fact check by GOV.UK Bot")
        end

        within :css, ".history__action--receive_fact_check__content" do
          assert page.has_text?("We’re happy for you to publish.")
          assert page.has_css?("div.js-earlier", text: "Reply and confirm the content is correct.")
          assert page.has_text?("We found some potentially harmful content in this email which has been automatically removed. Please check the content of the message in case any text has been deleted as well.")
        end
      end

      should "display 'Receive fact check' action with requester name when provided" do
        @edition.actions.create! request_type: Action::RECEIVE_FACT_CHECK, created_at: "2024-06-06 8:32:00", comment: "We’re happy for you to publish. -----Original Message----- Reply and confirm the content is correct.", comment_sanitized: true, requester_name: "Joe Bloggs"

        visit edition_path(@edition)
        click_link("History and notes")

        within :css, ".history__action--receive_fact_check__heading" do
          assert page.has_css?("time", text: "8:32am, 6 June 2024")
          assert page.has_text?("Receive fact check by Joe Bloggs")
        end

        within :css, ".history__action--receive_fact_check__content" do
          assert page.has_text?("We’re happy for you to publish.")
          assert page.has_css?("div.js-earlier", text: "Reply and confirm the content is correct.")
          assert page.has_text?("We found some potentially harmful content in this email which has been automatically removed. Please check the content of the message in case any text has been deleted as well.")
        end
      end

      should "display 'Request amendments' action" do
        user = FactoryBot.create(:user, name: "Brian Kilcline")
        @edition.actions.create! request_type: Action::REQUEST_AMENDMENTS, requester_id: user.id, created_at: "2024-06-27 10:56:00", comment: "Requesting amendments"

        visit edition_path(@edition)
        click_link("History and notes")

        within :css, ".history__action--request_amendments__heading" do
          assert page.has_css?("time", text: "10:56am, 27 June 2024")
          assert page.has_text?("Request amendments by Brian Kilcline")
        end

        within :css, ".history__action--request_amendments__content" do
          assert page.has_text?("Requesting amendments")
        end
      end

      should "display 'Approve review' action" do
        user = FactoryBot.create(:user, name: "Trevor Peake")
        @edition.actions.create! request_type: Action::APPROVE_REVIEW, requester_id: user.id, created_at: "2024-07-05 19:31:00", comment: "Review approved"

        visit edition_path(@edition)
        click_link("History and notes")

        within :css, ".history__action--approve_review__heading" do
          assert page.has_css?("time", text: "7:31pm, 5 July 2024")
          assert page.has_text?("Approve review by Trevor Peake")
        end

        within :css, ".history__action--approve_review__content" do
          assert page.has_text?("Review approved")
        end
      end

      should "display 'Content block update' action on Published and In Progress Editions" do
        user = FactoryBot.create(:user, :govuk_editor, name: "Dave Bennett")
        event = create_content_update_event(updated_by_user_uid: user["uid"])

        stub_events_for_all_content_ids(events: [event])
        stub_users_from_signon_api([user.uid], [user])

        visit edition_path(@edition)
        click_link("History and notes")

        within :css, ".history__action--content_block_update__heading" do
          assert page.has_css?("time", text: "11:26am, 7 August 2024")
          assert page.has_text?("Content block updated by Dave Bennett")
        end

        within :css, ".history__action--content_block_update__content" do
          assert page.has_text?("Email address updated")
          assert page.has_link?("View in Content Block Manager")
        end

        published_edition = FactoryBot.create(
          :edition,
          :published,
          created_at: Time.zone.parse(event["created_at"]).to_date - 1.day,
        )

        published_edition.actions.create!(
          request_type: Action::PUBLISH,
          requester: user,
        )

        visit edition_path(published_edition)
        click_link("History and notes")

        within :css, ".history__action--content_block_update__heading" do
          assert page.has_css?("time", text: "11:26am, 7 August 2024")
          assert page.has_text?("Content block updated by Dave Bennett")
        end

        within :css, ".history__action--content_block_update__content" do
          assert page.has_text?("Email address updated")
          assert page.has_link?("View in Content Block Manager")
        end
      end

      should "does not display 'Content block update' action on Editions archived before the update" do
        user = FactoryBot.create(:user, :govuk_editor, name: "Dave Bennett")
        archived_edition = FactoryBot.create(:edition, :archived)
        event = create_content_update_event(updated_by_user_uid: user["uid"])
        stub_events_for_all_content_ids(events: [event])
        stub_users_from_signon_api([user.uid], [user])

        visit edition_path(archived_edition)
        click_link("History and notes")

        assert page.has_no_css?(".history__action--content_block_update__heading")
        assert page.has_no_css?(".history__action--content_block_update__content")
      end
    end

    context "when there are previous editions" do
      should "display a link to compare editions" do
        edition_one = FactoryBot.create(:answer_edition, :published)
        edition_two = FactoryBot.create(
          :answer_edition,
          :published,
          panopticon_id: edition_one.panopticon_id,
          title: "Second edition title",
        )

        visit history_edition_path(edition_two)
        page.find("a", text: "Compare with Edition 1").click

        page.find("h1", text: "Compare edition 1 and 2")
        assert page.has_css?("h1", text: "Compare edition 1 and 2")
        assert page.has_content?(edition_two.title)
      end
    end

    context "when there are not previous editions" do
      should "not display a link to compare editions" do
        edition_one = FactoryBot.create(:answer_edition, :published)
        visit history_edition_path(edition_one)

        assert page.has_css?("h2", text: "History and notes")
        assert page.has_no_css?("a", text: "Compare with Edition")
      end
    end
  end

  context "Add edition note page" do
    should "render the 'Add edition note' page" do
      draft_edition = FactoryBot.create(:edition, :draft, title: "Example title")

      visit edition_path(draft_edition)
      click_link("History and notes")
      click_link("Add edition note")

      within :css, ".gem-c-heading" do
        assert page.has_css?("h1", text: "Add edition note")
        assert page.has_css?(".gem-c-heading__context", text: draft_edition.title)
      end

      assert page.has_text?("Explain what changes you did or did not make and why. Include a link to the relevant Zendesk ticket and Jira card. You can also add an edition note when you send the edition for 2i review. Read guidance on writing good change notes (opens in new tab).")

      within :css, ".gem-c-textarea" do
        assert page.has_css?("label", text: "Edition note")
        assert page.has_css?("textarea")
      end

      assert page.has_button?("Save")
      assert page.has_link?("Cancel")
    end
  end

  context "Update important note page" do
    setup do
      @draft_edition = FactoryBot.create(:edition, :draft)
    end

    should "render the 'Update important note' page" do
      visit history_update_important_note_edition_path(@draft_edition)

      within :css, ".gem-c-heading" do
        assert page.has_css?("h1", text: "Update important note")
        assert page.has_css?(".gem-c-heading__context", text: @draft_edition.title)
      end

      assert page.has_text?("Add important notes that anyone who works on this edition needs to see, eg “(Doesn’t) need fact check, don’t publish.”.")
      assert page.has_text?("Each edition can have only one important note at a time.")
      assert page.has_text?("To delete the important note, clear any comments and select ‘Save’.")

      within :css, ".gem-c-textarea" do
        assert page.has_css?("label", text: "Important note")
        assert page.has_css?("textarea")
      end

      assert page.has_button?("Save")
      assert page.has_link?("Cancel")
    end

    should "pre-populate with the existing note" do
      note_text = "This is really really urgent!"
      create_important_note_for_edition(@draft_edition, note_text)

      visit history_update_important_note_edition_path(@draft_edition)

      assert page.has_field?("Important note", with: note_text)
    end

    should "not show important notes in edition history" do
      note_text = "This is really really urgent!"
      note_text_2 = "Another note"
      note_text_3 = "Yet another note"
      create_important_note_for_edition(@draft_edition, note_text)
      create_important_note_for_edition(@draft_edition, note_text_2)
      create_important_note_for_edition(@draft_edition, note_text_3)

      visit edition_path(@draft_edition)
      click_link("History and notes")

      within :css, ".history__actions" do
        assert page.has_no_text?("Important note updated by #{@govuk_editor.name}")
        assert page.has_no_text?("This is really really urgent!")
        assert page.has_no_text?("Another note")
        assert page.has_no_text?("Yet another note")
      end
    end

    should "not be carried forward to new editions" do
      published_edition = FactoryBot.create(:edition, :published)
      note_text = "This important note should not appear on a new edition."
      create_important_note_for_edition(published_edition, note_text)

      visit edition_path(published_edition)

      assert page.has_content? note_text

      click_on "Create new edition"
      assert page.has_no_text?("Important note")
    end
  end

  context "Compare editions" do
    should "render the compare editions page" do
      published_edition = FactoryBot.create(:edition, :published)
      draft_edition = FactoryBot.create(
        :edition,
        :draft,
        panopticon_id: published_edition.panopticon_id,
        body: "Some added text",
      )

      visit diff_edition_path(draft_edition)

      assert page.has_content?(draft_edition.title)
      assert page.has_content?("Compare edition 1 and 2")
      assert page.has_content?("Answer")
      assert page.has_content?("2 Draft")
      assert page.has_link?("Back to History and notes", href: history_edition_path(draft_edition))
      assert page.has_css?("li.ins", text: "Some added text")
    end
  end
end
