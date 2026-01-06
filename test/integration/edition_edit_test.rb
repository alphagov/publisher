require "integration_test_helper"

class EditionEditTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    @govuk_requester = FactoryBot.create(:user, :govuk_editor, name: "Stub requester")
    login_as(@govuk_editor)
    @test_strategy = Flipflop::FeatureSet.current.test!
    @test_strategy.switch!(:design_system_edit_phase_3a, true)
    UpdateWorker.stubs(:perform_async)
  end

  context "edit page" do
    should "show all the tabs when user has required permission and edition is published" do
      published_edition = FactoryBot.create(:edition, :published)
      visit edition_path(published_edition)

      assert page.has_text?("Edit")
      assert page.has_text?("Tagging")
      assert page.has_text?("Metadata")
      assert page.has_text?("History and notes")
      assert page.has_text?("Admin")
      assert page.has_text?("Related external links")
      assert page.has_text?("Unpublish")
    end

    should "show document summary and title" do
      published_edition = FactoryBot.create(:edition, :published, title: "Edit page title")
      visit edition_path(published_edition)

      assert page.has_title?("Edit page title")
      row = find_all(".govuk-summary-list__row")
      assert row[0].has_content?("Assigned to")
      assert row[1].has_text?("Content type")
      assert row[1].has_text?("Answer")
      assert row[2].has_text?("Edition")
      assert row[2].has_text?("1")
      assert row[2].has_text?("Published")
    end

    should "show scheduled date and time when an edition is scheduled for publishing" do
      travel_to Time.zone.local(2025, 3, 4, 17, 16, 15)
      scheduled_for_publishing_edition = FactoryBot.create(
        :edition,
        :scheduled_for_publishing,
        publish_at: Time.zone.now,
      )

      visit edition_path(scheduled_for_publishing_edition)

      row = find_all(".govuk-summary-list__row")
      assert_equal 4, row.count, "Expected four rows in the summary"
      assert row[2].has_text?(/Scheduled for publishing$/)
      assert row[3].has_text?("Scheduled")
      assert row[3].has_text?("5:16pm, 4 March 2025")
    end

    %i[draft amends_needed fact_check_received ready archived published].each do |state|
      should "not show a scheduled row when an edition is in the '#{state}' state" do
        edition = FactoryBot.create(:edition, state)
        visit edition_path(edition)

        row = find_all(".govuk-summary-list__row")
        assert_equal 3, row.count, "Expected three rows in the summary"
        assert page.has_no_content?("Scheduled")
      end
    end

    should "not show a scheduled row when an edition is in the 'in_review' state" do
      edition = FactoryBot.create(:edition, :in_review, review_requested_at: 1.hour.ago)
      visit edition_path(edition)

      row = find_all(".govuk-summary-list__row")
      assert_equal 4, row.count, "Expected four rows in the summary"
      assert page.has_no_content?("Scheduled")
    end

    should "indicate when an edition does not have an assignee" do
      published_edition = FactoryBot.create(:edition, :published)
      visit edition_path(published_edition)

      within all(".govuk-summary-list__row")[0] do
        assert_selector(".govuk-summary-list__key", text: "Assigned to")
        assert_selector(".govuk-summary-list__value", text: "None")
      end
    end

    should "show the person assigned to an edition" do
      draft_edition = FactoryBot.create(:edition, :draft)
      visit edition_path(draft_edition)

      within all(".govuk-summary-list__row")[0] do
        assert_selector(".govuk-summary-list__key", text: "Assigned to")
        assert_selector(".govuk-summary-list__value", text: draft_edition.assignee)
      end
    end

    should "not show the 2i reviewer row in the summary if the edition state is not 'in_review'" do
      %i[draft amends_needed fact_check fact_check_received ready scheduled_for_publishing published archived].each do |state|
        edition = FactoryBot.create(:edition, state)
        visit edition_path(edition)

        within :css, ".govuk-summary-list" do
          assert_no_selector(".govuk-summary-list__key", text: "2i reviewer")
        end
      end
    end

    should "show the 2i reviewer row in the summary correctly if the edition state is 'in_review' and a reviewer is not assigned" do
      in_review_edition = FactoryBot.create(:edition, :in_review)
      visit edition_path(in_review_edition)

      within all(".govuk-summary-list__row")[3] do
        assert_selector(".govuk-summary-list__key", text: "2i reviewer")
        assert_selector(".govuk-summary-list__value", text: "Not yet claimed")
      end
    end

    should "show the 2i reviewer row in the summary correctly if the edition state is 'in_review' and a reviewer is assigned" do
      edition = FactoryBot.create(:edition, :in_review, reviewer: @govuk_editor)
      visit edition_path(edition)

      within all(".govuk-summary-list__row")[3] do
        assert_selector(".govuk-summary-list__key", text: "2i reviewer")
        assert_selector(".govuk-summary-list__value", text: "Stub User")
      end
    end

    should "display the important note if an important note exists" do
      note_text = "This is really really urgent!"
      draft_edition = FactoryBot.create(:edition, :draft)
      create_important_note_for_edition(draft_edition, note_text)

      visit edition_path(draft_edition)

      within :css, ".govuk-notification-banner" do
        assert page.has_text?("Important")
        assert page.has_text?(note_text)
        assert page.has_text?(@govuk_editor.name)
        assert page.has_text?(Time.zone.today.to_date.to_fs(:govuk_date))
      end
    end

    should "display only the most recent important note at the top" do
      first_note = "This is really really urgent!"
      second_note = "This should display only!"
      draft_edition = FactoryBot.create(:edition, :draft)
      create_important_note_for_edition(draft_edition, first_note)
      create_important_note_for_edition(draft_edition, second_note)

      visit edition_path(draft_edition)

      assert page.has_text?("Important")
      assert page.has_text?(second_note)
      assert page.has_no_text?(first_note)
    end
  end

  context "edit assignee page" do
    should "only show editors as available for assignment" do
      edition = FactoryBot.create(:edition, :draft)
      non_editor_user = FactoryBot.create(:user, name: "Non Editor User")

      visit edit_assignee_edition_path(edition)

      assert_selector "label", text: @govuk_editor.name
      assert_no_selector "label", text: non_editor_user.name
    end
  end

  context "edit tab" do
    context "archived edition" do
      setup do
        @archived_edition = FactoryBot.create(:edition, :archived)
      end

      should "show a message when all editions are unpublished" do
        published_edition = FactoryBot.create(:edition, :published)
        new_edition = FactoryBot.create(
          :edition,
          :draft,
          panopticon_id: published_edition.artefact.id,
        )
        new_edition.artefact.state = "archived"
        new_edition.artefact.save!

        visit edition_path(new_edition)

        assert page.has_text?("This content has been unpublished and is no longer available on the website. All editions have been archived.")
      end

      should "not show the sidebar" do
        visit edition_path(@archived_edition)
        assert page.has_no_css?(".sidebar-components")
      end

      should "show common content-type fields" do
        archived_edition = FactoryBot.create(:edition, :archived, in_beta: true)
        visit edition_path(archived_edition)

        assert page.has_css?("h3", text: "Title")
        assert page.has_css?("p", text: archived_edition.title)
        assert page.has_css?("h3", text: "Meta tag description")
        assert page.has_css?("p", text: archived_edition.overview)
        assert page.has_css?("h3", text: "Is this beta content?")
        assert page.has_css?("p", text: "Yes")

        archived_edition.in_beta = false
        archived_edition.save!(validate: false)
        visit edition_path(archived_edition)

        assert page.has_css?("p", text: "No")
      end

      should "show body field" do
        visit edition_path(@archived_edition)

        assert page.has_css?("h3", text: "Body")
        assert page.has_css?("div", text: @archived_edition.body)
      end

      should "show public change field" do
        visit edition_path(@archived_edition)

        assert page.has_css?("h3", text: "Public change note")
        assert page.has_css?("p", text: "None added")

        @archived_edition.major_change = true
        @archived_edition.change_note = "Change note for test"
        @archived_edition.save!(validate: false)
        visit edition_path(@archived_edition)

        assert page.has_text?(@archived_edition.change_note)
      end
    end

    context "Fact check edition" do
      %i[draft in_review amends_needed fact_check_received ready scheduled_for_publishing published archived].each do |state|
        context "when state is '#{state}'" do
          should "not show the 'Resend fact check email' link and text" do
            edition = FactoryBot.create(:edition, state)

            visit edition_path(edition)

            assert page.has_no_link?("Resend fact check email")
            assert page.has_no_text?("You've requested this edition to be fact checked. We're awaiting a response.")
          end
        end
      end

      context "when state is 'Fact check" do
        setup do
          @fact_check_edition = FactoryBot.create(:edition, :fact_check, requester: @govuk_editor)
        end

        should "not show the link or text to non-editors" do
          login_as(FactoryBot.create(:user, name: "Stub User"))
          visit edition_path(@fact_check_edition)

          assert page.has_no_link?("Resend fact check email")
          assert page.has_no_text?("You've requested this edition to be fact checked. We're awaiting a response.")
        end

        should "not show the link or text to welsh editors viewing a non-welsh edition" do
          login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
          visit edition_path(@fact_check_edition)

          assert page.has_no_link?("Resend fact check email")
          assert page.has_no_text?("You've requested this edition to be fact checked. We're awaiting a response.")
        end

        should "show the 'Resend fact check email' link and text to govuk editors" do
          login_as(@govuk_editor)
          visit edition_path(@fact_check_edition)

          assert page.has_link?("Resend fact check email")
          assert page.has_text?("You've requested this edition to be fact checked. We're awaiting a response.")
        end

        should "show the requester specific text to govuk editors" do
          login_as(@govuk_editor)
          @fact_check_edition = FactoryBot.create(:edition, :fact_check, requester: @govuk_requester)

          visit edition_path(@fact_check_edition)

          assert page.has_text?("Stub requester requested this edition to be fact checked. We're awaiting a response.")
        end

        should "show Preview link" do
          visit edition_path(@fact_check_edition)
          assert page.has_link?("Preview (opens in new tab)")
        end

        context "user does not have editor permissions" do
          setup do
            login_as(FactoryBot.create(:user, name: "Non Editor"))
            visit edition_path(@fact_check_edition)
          end

          should "not show any editable components" do
            assert page.has_no_css?(".govuk-textarea")
            assert page.has_no_css?(".govuk-input")
            assert page.has_no_css?(".govuk-radios")
          end

          should "not show the Save button" do
            assert page.has_no_button?("Save")
          end

          should "show the Preview link" do
            assert page.has_link?("Preview (opens in new tab)")
          end
        end
      end

      context "when state is 'Fact check received'" do
        context "when user has govuk editor permissions" do
          setup do
            login_as(FactoryBot.create(:user, :govuk_editor))
            @fact_check_received_edition = FactoryBot.create(:edition, :fact_check_received)
            visit edition_path(@fact_check_received_edition)
          end

          should "show Preview link" do
            assert page.has_link?("Preview (opens in new tab)")
          end

          should "show the fact check inset text" do
            assert page.has_text?("We have received a fact check response for this edition.")
            assert page.has_text?("Please check the response in History and notes and select an action below.")
          end

          context "user does not have editor permissions" do
            setup do
              login_as(FactoryBot.create(:user, name: "Non Editor"))
              visit edition_path(@fact_check_received_edition)
            end

            should "not show any editable components" do
              assert page.has_no_css?(".govuk-textarea")
              assert page.has_no_css?(".govuk-input")
              assert page.has_no_css?(".govuk-radios")
            end

            should "not show the Save button" do
              assert page.has_no_button?("Save")
            end

            should "not show the fact check inset text" do
              assert page.has_no_text?("We have received a fact check response for this edition./nPlease check the response in History & Notes, and select an action below.")
            end

            should "show the Preview link" do
              assert page.has_link?("Preview (opens in new tab)")
            end
          end

          should "navigate to the 'Resend fact check email' page when the link is clicked" do
            login_as(@govuk_editor)
            fact_check_edition = FactoryBot.create(:edition, :fact_check)

            visit edition_path(fact_check_edition)
            click_link("Resend fact check email")

            assert_current_path resend_fact_check_email_page_edition_path(fact_check_edition.id)
          end
        end
      end

      context "Request amendments link" do
        context "edition is not in review" do
          should "not show the link for a draft edition" do
            draft_edition = FactoryBot.create(:edition, :draft)
            visit edition_path(draft_edition)

            assert page.has_no_link?("Request amendments")
          end
        end

        context "edition is in review" do
          setup do
            @in_review_edition = FactoryBot.create(:edition, :in_review, requester: @govuk_requester)
          end

          should "not show the link to non-editors" do
            login_as(FactoryBot.create(:user, name: "Stub User"))
            visit edition_path(@in_review_edition)

            assert page.has_no_link?("Request amendments")
          end

          should "not show the link to welsh editors viewing a non-welsh edition" do
            login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
            visit edition_path(@in_review_edition)

            assert page.has_no_link?("Request amendments")
          end

          should "not show the link to the requester" do
            login_as(@govuk_requester)
            visit edition_path(@in_review_edition)

            assert page.has_no_link?("Request amendments")
          end

          should "show the link to editors who are not the requester" do
            login_as(@govuk_editor)
            visit edition_path(@in_review_edition)

            assert page.has_link?("Request amendments")
          end

          should "navigate to the 'Request amendments' page when the link is clicked" do
            login_as(@govuk_editor)

            visit edition_path(@in_review_edition)
            click_link("Request amendments")

            assert_current_path request_amendments_page_edition_path(@in_review_edition.id)
          end
        end

        context "edition is ready" do
          setup do
            @ready_edition = FactoryBot.create(:answer_edition, :ready)
          end

          should "not show the link to non-editors" do
            login_as(FactoryBot.create(:user, name: "Stub User"))
            visit edition_path(@ready_edition)

            assert page.has_no_link?("Request amendments")
          end

          should "not show the link to welsh editors viewing a non-welsh edition" do
            login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
            visit edition_path(@ready_edition)

            assert page.has_no_link?("Request amendments")
          end

          should "show the link to editors" do
            login_as(@govuk_editor)
            visit edition_path(@ready_edition)

            assert page.has_link?("Request amendments")
          end

          should "navigate to the 'Request amendments' page when the link is clicked" do
            login_as(@govuk_editor)

            visit edition_path(@ready_edition)
            click_link("Request amendments")

            assert_current_path request_amendments_page_edition_path(@ready_edition.id)
          end
        end

        context "edition is out for fact check" do
          setup do
            @fact_check_edition = FactoryBot.create(:edition, :fact_check)
          end

          should "not show the link to non editors" do
            login_as(FactoryBot.create(:user, name: "Stub User"))
            visit edition_path(@fact_check_edition)

            assert page.has_no_link?("Request amendments")
          end

          should "not show the link to welsh editors viewing a non-welsh edition" do
            login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
            visit edition_path(@fact_check_edition)

            assert page.has_no_link?("Request amendments")
          end

          should "show the link to editors" do
            login_as(@govuk_editor)
            visit edition_path(@fact_check_edition)

            assert page.has_link?("Request amendments")
          end

          should "show the link to welsh editors viewing a welsh edition" do
            login_as_welsh_editor
            welsh_edition = FactoryBot.create(:edition, :welsh, :ready)

            visit edition_path(welsh_edition)

            assert page.has_link?("Request amendments")
          end

          should "navigate to the 'Request amendments' page when the link is clicked" do
            login_as(@govuk_editor)

            visit edition_path(@fact_check_edition)
            click_link("Request amendments")

            assert_current_path request_amendments_page_edition_path(@fact_check_edition.id)
          end
        end

        context "edition is fact check received" do
          setup do
            @fact_check_received_edition = FactoryBot.create(:edition, :fact_check_received)
          end

          should "not show the link to non editors" do
            login_as(FactoryBot.create(:user, name: "Stub User"))
            visit edition_path(@fact_check_received_edition)

            assert page.has_no_link?("Request amendments")
          end

          should "not show the link to welsh editors viewing a non-welsh edition" do
            login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
            visit edition_path(@fact_check_received_edition)

            assert page.has_no_link?("Request amendments")
          end

          should "show the link to editors" do
            login_as(@govuk_editor)
            visit edition_path(@fact_check_received_edition)

            assert page.has_link?("Request amendments")
          end

          should "show the link to welsh editors viewing a welsh edition" do
            login_as_welsh_editor
            welsh_edition = FactoryBot.create(:edition, :welsh, :fact_check_received)

            visit edition_path(welsh_edition)

            assert page.has_link?("Request amendments")
          end

          should "navigate to the 'Request amendments' page when the link is clicked" do
            login_as(@govuk_editor)

            visit edition_path(@fact_check_received_edition)
            click_link("Request amendments")

            assert_current_path request_amendments_page_edition_path(@fact_check_received_edition.id)
          end
        end
      end

      context "No changes needed link (fact_check_received state)" do
        context "edition is fact check received" do
          setup do
            @fact_check_received_edition = FactoryBot.create(:edition, :fact_check_received)
          end

          should "not show the link to non editors" do
            login_as(FactoryBot.create(:user, name: "Stub User"))
            visit edition_path(@fact_check_received_edition)

            assert page.has_no_link?("No changes needed")
          end

          should "not show the link to welsh editors viewing a non-welsh edition" do
            login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
            visit edition_path(@fact_check_received_edition)

            assert page.has_no_link?("No changes needed")
          end

          should "show the link to editors" do
            login_as(@govuk_editor)
            visit edition_path(@fact_check_received_edition)

            assert page.has_link?("No changes needed")
          end

          should "show the link to welsh editors viewing a welsh edition" do
            login_as_welsh_editor
            welsh_edition = FactoryBot.create(:edition, :welsh, :fact_check_received)

            visit edition_path(welsh_edition)

            assert page.has_link?("No changes needed")
          end

          should "navigate to the 'Approve fact check' page when the link is clicked" do
            login_as(@govuk_editor)

            visit edition_path(@fact_check_received_edition)
            click_link("No changes needed")

            assert_current_path approve_fact_check_page_edition_path(@fact_check_received_edition.id)
          end
        end
      end

      context "No changes needed link (in_review state)" do
        context "edition is not in review" do
          should "not show the link" do
            draft_edition = FactoryBot.create(:edition, :draft)
            visit edition_path(draft_edition)

            assert page.has_no_link?("No changes needed")
          end
        end

        context "edition is in review" do
          setup do
            @in_review_edition = FactoryBot.create(:edition, :in_review, requester: @govuk_requester)
          end

          should "not show the link to non-editors" do
            login_as(FactoryBot.create(:user, name: "Stub User"))
            visit edition_path(@in_review_edition)

            assert page.has_no_link?("No changes needed")
          end

          should "not show the link to welsh editors viewing a non-welsh edition" do
            login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
            visit edition_path(@in_review_edition)

            assert page.has_no_link?("No changes needed")
          end

          should "not show the link to the requester" do
            login_as(@govuk_requester)
            visit edition_path(@in_review_edition)

            assert page.has_no_link?("No changes needed")
          end

          should "show the link to editors who are not the requester" do
            login_as(@govuk_editor)
            visit edition_path(@in_review_edition)

            assert page.has_link?("No changes needed")
          end

          should "navigate to the 'No changes needed' page when the link is clicked" do
            login_as(@govuk_editor)

            visit edition_path(@in_review_edition)
            click_link("No changes needed")

            assert_current_path no_changes_needed_page_edition_path(@in_review_edition.id)
          end
        end
      end

      context "Skip review link" do
        context "viewing an 'in review' edition as the review requester" do
          setup do
            @edition = FactoryBot.create(:edition, :in_review, review_requested_at: 1.hour.ago)
            @requester = FactoryBot.create(:user)
            @edition.actions.create!(
              request_type: Action::REQUEST_AMENDMENTS,
              requester_id: @requester.id,
            )
            login_as(@requester)
          end

          should "show the 'Skip review' link when the user has the 'skip_review' permission" do
            @requester.permissions << "skip_review"
            visit edition_path(@edition)

            assert page.has_link?("Skip review")
          end

          should "navigate to 'Skip review' page when 'Skip review' link is clicked" do
            @requester.permissions << "skip_review"

            visit edition_path(@edition)
            click_link("Skip review")

            assert_current_path skip_review_page_edition_path(@edition.id)
          end

          should "not show the 'Skip review' link when the user does not have the 'skip_review' permission" do
            visit edition_path(@edition)

            assert page.has_no_link?("Skip review")
          end
        end

        context "viewing an 'in review' edition as somebody other than the review requester" do
          should "not show the 'Skip review' link" do
            edition = FactoryBot.create(:edition, :in_review, review_requested_at: 1.hour.ago)
            user = FactoryBot.create(:user, :skip_review)
            login_as(user)

            visit edition_path(edition)

            assert page.has_no_link?("Skip review")
          end
        end

        should "not show the 'Skip review' link when viewing an edition that is not 'in review'" do
          edition = FactoryBot.create(:edition, :draft)
          user = FactoryBot.create(:user, :skip_review)
          login_as(user)

          visit edition_path(edition)

          assert page.has_no_link?("Skip review")
        end
      end

      context "edit assignee link" do
        context "user does not have required permissions" do
          setup do
            login_as(FactoryBot.create(:user, name: "Stub User"))
            @draft_edition = FactoryBot.create(:edition, :draft)
            visit edition_path(@draft_edition)
          end

          should "not show 'Edit' link when user is not govuk editor or welsh editor" do
            within :css, ".editions__edit__summary" do
              within all(".govuk-summary-list__row")[0] do
                assert page.has_no_link?("Edit")
              end
            end
          end

          should "not show 'Edit' link when user is welsh editor and edition is not welsh" do
            login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
            visit edition_path(@draft_edition)

            within :css, ".editions__edit__summary" do
              within all(".govuk-summary-list__row")[0] do
                assert page.has_no_link?("Edit")
              end
            end
          end
        end

        context "user has required permissions" do
          %i[published archived scheduled_for_publishing].each do |state|
            context "when state is '#{state}'" do
              setup do
                edition = FactoryBot.create(:edition, state)
                visit edition_path(edition)
              end

              should "not show 'Edit' link" do
                within :css, ".editions__edit__summary" do
                  within all(".govuk-summary-list__row")[0] do
                    assert page.has_no_link?("Edit")
                  end
                end
              end
            end
          end

          %i[draft amends_needed in_review fact_check_received fact_check ready].each do |state|
            context "when state is '#{state}'" do
              setup do
                edition = FactoryBot.create(:edition, state)
                visit edition_path(edition)
                click_link("Admin")
              end

              should "show 'Edit' link" do
                within :css, ".editions__edit__summary" do
                  within all(".govuk-summary-list__row")[0] do
                    assert page.has_link?("Edit")
                  end
                end
              end

              should "navigate to edit assignee page when 'Edit' assignee is clicked" do
                within :css, ".editions__edit__summary" do
                  within all(".govuk-summary-list__row")[0] do
                    click_link("Edit")
                  end
                end

                assert(page.current_path.include?("/edit_assignee"))
              end
            end
          end

          context "edit assignee page" do
            setup do
              @draft_edition = FactoryBot.create(:edition, :draft)
              visit edition_path(@draft_edition)
              within :css, ".editions__edit__summary" do
                within all(".govuk-summary-list__row")[0] do
                  click_link("Edit")
                end
              end
            end

            should "show title and page title" do
              assert page.has_title?("Assign person")
              assert page.has_text?(@draft_edition.title)
            end

            should "show only enabled users as radio button options" do
              FactoryBot.create(:user, name: "Disabled User", disabled: true)
              all_enabled_users_names = []
              User.enabled.each { |user| all_enabled_users_names << user.name }
              all_user_radio_buttons = find_all(".govuk-radios__item").map(&:text)

              assert all_user_radio_buttons.exclude?("Disabled User")

              all_enabled_users_names.each do |users|
                assert all_user_radio_buttons.include?(users)
              end
            end

            should "allow currently assigned user to be unassigned" do
              user = FactoryBot.create(:user, :govuk_editor)
              @govuk_editor.assign(@draft_edition, user)

              visit current_path
              choose "None"
              click_on "Save"

              assert_equal(page.current_path, "/editions/#{@draft_edition.id}")
            end

            should "navigate to editions edit page when 'Cancel' link is clicked" do
              click_link("Cancel")
              assert_equal(page.current_path, "/editions/#{@draft_edition.id}")
            end
          end
        end
      end

      context "edit 2i reviewer link" do
        setup do
          @in_review_edition = FactoryBot.create(:edition, :in_review)
        end

        context "user does not have required permissions" do
          setup do
            login_as(FactoryBot.create(:user, name: "Stub User"))
            visit edition_path(@in_review_edition)
          end

          should "not show 'Edit' link when user is not govuk editor or welsh editor" do
            within :css, ".editions__edit__summary" do
              within all(".govuk-summary-list__row")[3] do
                assert page.has_no_link?("Edit")
              end
            end
          end

          should "not show 'Edit' link when user is welsh editor and edition is not welsh" do
            login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
            visit edition_path(@in_review_edition)

            within :css, ".editions__edit__summary" do
              within all(".govuk-summary-list__row")[3] do
                assert page.has_no_link?("Edit")
              end
            end
          end
        end

        context "user has required permissions" do
          should "show 'Edit' link" do
            visit edition_path(@in_review_edition)

            within :css, ".editions__edit__summary" do
              within all(".govuk-summary-list__row")[3] do
                assert page.has_link?("Edit")
              end
            end
          end

          should "navigate to edit 2i reviewer page when 'Edit' link is clicked" do
            visit edition_path(@in_review_edition)

            within :css, ".editions__edit__summary" do
              within all(".govuk-summary-list__row")[3] do
                click_link("Edit")
              end
            end

            assert(page.current_path.include?("/edit_reviewer"))
          end

          context "edit reviewer page" do
            setup do
              @edition = FactoryBot.create(:edition, :in_review, reviewer: @govuk_editor.id)
              visit edit_reviewer_edition_path(@edition)
            end

            should "show title and page title" do
              assert page.has_title?("Assign 2i reviewer")
              assert page.has_text?(@edition.title)
            end

            should "navigate to editions edit page when 'Cancel' link is clicked" do
              click_link("Cancel")
              assert_equal(page.current_path, "/editions/#{@edition.id}")
            end

            context "radio buttons" do
              setup do
                FactoryBot.create(:user, name: "Disabled User", disabled: true)
                @all_enabled_users_names = []
                User.enabled.each { |user| @all_enabled_users_names << user.name }
                @all_user_radio_buttons = find_all(".govuk-radios__item").map(&:text)
              end

              should "show only enabled users as radio button options" do
                assert @all_user_radio_buttons.exclude?("Disabled User")

                @all_enabled_users_names.each do |users|
                  assert @all_user_radio_buttons.include?(users)
                end
              end

              should "show the currently assigned reviewer as the first radio button option and 'none' as the second" do
                within all(".govuk-radios__item")[0] do
                  assert page.has_css?("input[value='#{@govuk_editor.id}']")
                end

                within all(".govuk-radios__item")[1] do
                  assert page.has_css?("input[value='none']")
                end
              end

              should "not show a 'none' option when there is no assigned reviewer" do
                edition_no_reviewer = FactoryBot.create(:edition, :in_review, reviewer: nil)
                visit edit_reviewer_edition_path(edition_no_reviewer)

                within :css, ".govuk-radios" do
                  assert page.has_no_css?("input[value='none']")
                end
              end
            end
          end
        end
      end

      context "content block guidance" do
        context "when show_link_to_content_block_manager? is false" do
          setup do
            @test_strategy.switch!(:show_link_to_content_block_manager, false)
            @draft_edition = FactoryBot.create(:edition, :draft)
            visit edition_path(@draft_edition)
          end

          should "not show the content block guidance" do
            assert_not page.has_text?("Use Content Block Manager (opens in new tab) to create, edit and use standardised content across GOV.UK")
          end
        end

        context "when show_link_to_content_block_manager? is true" do
          setup do
            @test_strategy.switch!(:show_link_to_content_block_manager, true)
          end

          %i[draft ready published archived].each do |state|
            should "show the content block guidance with content in #{state} state" do
              transaction_edition = FactoryBot.create(:transaction_edition, state)
              visit edition_path(transaction_edition)

              assert page.has_text?("Use Content Block Manager (opens in new tab) to create, edit and use standardised content across GOV.UK")
            end

            should "not show the content block guidance when content type has no GOVSPEAK field in #{state} state" do
              completed_transaction_edition = FactoryBot.create(:completed_transaction_edition, state)
              visit edition_path(completed_transaction_edition)

              assert_not page.has_text?("Use Content Block Manager (opens in new tab) to create, edit and use standardised content across GOV.UK")
            end
          end
        end
      end

      context "'Publish' button" do
        should "show the 'Publish' button if user has govuk_editor permission" do
          login_as(@govuk_editor)
          ready_edition = FactoryBot.create(:answer_edition, :ready)

          visit edition_path(ready_edition)

          assert page.has_link?("Publish", href: send_to_publish_page_edition_path(ready_edition))
        end

        should "show the 'Publish' button for welsh edition if user has welsh_editor permission" do
          login_as_welsh_editor
          welsh_edition = FactoryBot.create(:edition, :welsh, :ready)

          visit edition_path(welsh_edition)

          assert @user.has_editor_permissions?(welsh_edition)
          assert page.has_link?("Publish", href: send_to_publish_page_edition_path(welsh_edition))
        end

        should "not show the 'Publish' button if the user does not have permissions" do
          login_as(FactoryBot.create(:user, name: "Stub User"))
          ready_edition = FactoryBot.create(:answer_edition, :ready)

          visit edition_path(ready_edition)

          assert_not page.has_link?("Publish", href: send_to_publish_page_edition_path(ready_edition))
        end
      end

      context "'Fact check' button" do
        %i[ready fact_check_received].each do |state|
          should "show the 'Fact check' button on '#{state}' if user has govuk_editor permission" do
            login_as(@govuk_editor)
            edition = FactoryBot.create(:edition, state)

            visit edition_path(edition)

            assert page.has_link?("Fact check", href: send_to_fact_check_page_edition_path(edition))
          end

          should "show the 'Fact check' button on '#{state}' for welsh edition if user has welsh_editor permission" do
            login_as_welsh_editor
            welsh_edition = FactoryBot.create(:edition, :welsh, state)

            visit edition_path(welsh_edition)

            assert @user.has_editor_permissions?(welsh_edition)
            assert page.has_link?("Fact check", href: send_to_fact_check_page_edition_path(welsh_edition))
          end

          should "not show the 'Fact check' button on '#{state}' if the user does not have permissions" do
            login_as(FactoryBot.create(:user, name: "Stub User"))
            edition = FactoryBot.create(:edition, state)

            visit edition_path(edition)

            assert page.has_no_link?("Fact check", href: "#")
          end
        end
      end
    end
  end
end
