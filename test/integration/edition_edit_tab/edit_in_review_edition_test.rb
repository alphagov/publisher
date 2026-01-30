require "integration_test_helper"

class EditInReviewEditionTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    @govuk_requester = FactoryBot.create(:user, :govuk_editor, name: "Stub requester")
    login_as(@govuk_editor)
  end

  context "user has the required permissions" do
    context "current user is also the requester" do
      setup do
        login_as(@govuk_requester)
        @in_review_edition = FactoryBot.create(:edition, :in_review, requester: @govuk_requester)
        visit edition_path(@in_review_edition)
      end

      should "display Save button and preview link" do
        assert page.has_button?("Save"), "No save button present"
        assert page.has_link?("Preview (opens in new tab)"), "No preview link present"
      end

      should "indicate that the current user requested a review" do
        assert page.has_text?("You've sent this edition to be reviewed")
      end

      should "not show 'Send to 2i' link as edition already in 'in review' state" do
        visit edition_path(@in_review_edition)
        assert page.has_no_link?("Send to 2i")
      end

      should "not show the 'Resend fact check email' link and text" do
        assert page.has_no_link?("Resend fact check email")
        assert page.has_no_text?("You've requested this edition to be fact checked. We're awaiting a response.")
      end

      should "not show the 'Request amendments' link" do
        assert page.has_no_link?("Request amendments")
      end

      should "not show the 'No changes needed' link" do
        assert page.has_no_link?("No changes needed")
      end

      should "show the 'Skip review' link when the user has the 'skip_review' permission" do
        @govuk_requester.permissions << "skip_review"
        login_as(@govuk_requester)

        visit edition_path(@in_review_edition)

        assert page.has_link?("Skip review")
      end

      should "navigate to 'Skip review' page when 'Skip review' link is clicked" do
        @govuk_requester.permissions << "skip_review"
        login_as(@govuk_requester)

        visit edition_path(@in_review_edition)
        click_link("Skip review")

        assert_current_path skip_review_page_edition_path(@in_review_edition.id)
      end

      should "not show the 'Skip review' link when the user does not have the 'skip_review' permission" do
        assert page.has_no_link?("Skip review")
      end
    end

    context "current user is not the requester" do
      setup do
        login_as(@govuk_editor)
        @in_review_edition = FactoryBot.create(:edition, :in_review, requester: @govuk_requester)
        visit edition_path(@in_review_edition)
      end

      should "display Save button and preview link" do
        assert page.has_button?("Save"), "No save button present"
        assert page.has_link?("Preview (opens in new tab)"), "No preview link present"
      end

      should "indicate which other user requested a review" do
        assert page.has_text?("Stub requester sent this edition to be reviewed")
      end

      should "not show the 'Resend fact check email' link and text" do
        assert page.has_no_link?("Resend fact check email")
        assert page.has_no_text?("You've requested this edition to be fact checked. We're awaiting a response.")
      end

      should "show the 'Request amendments' link" do
        assert page.has_link?("Request amendments")
      end

      should "navigate to the 'Request amendments' page when the link is clicked" do
        click_link("Request amendments")
        assert_current_path request_amendments_page_edition_path(@in_review_edition.id)
      end

      should "show the 'No changes needed' link" do
        assert page.has_link?("No changes needed")
      end

      should "navigate to the 'No changes needed' page when the link is clicked" do
        click_link("No changes needed")
        assert_current_path no_changes_needed_page_edition_path(@in_review_edition.id)
      end

      should "not show the 'Skip review' link" do
        @govuk_editor.permissions << "skip_review"
        login_as(@govuk_editor)

        visit edition_path(@in_review_edition)

        assert page.has_no_link?("Skip review")
      end
    end
  end

  context "user does not have editor permissions" do
    setup do
      login_as(FactoryBot.create(:user, name: "Non Editor"))
      @in_review_edition = FactoryBot.create(:edition, :in_review)
      visit edition_path(@in_review_edition)
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

    should "not show the 'Request amendments' link" do
      assert page.has_no_link?("Request amendments")
    end

    should "not show the 'No changes needed' link" do
      assert page.has_no_link?("No changes needed")
    end
  end

  context "when a welsh editor" do
    setup do
      @welsh_editor = FactoryBot.create(:user, :welsh_editor, name: "Stub user")
      login_as(@welsh_editor)
    end

    context "when viewing a welsh edition as the requester" do
      setup do
        @welsh_edition = FactoryBot.create(:edition, :in_review, :welsh, requester: @welsh_editor)
        visit edition_path(@welsh_edition)
      end

      should "display Save button and preview link" do
        assert page.has_button?("Save"), "No save button present"
        assert page.has_link?("Preview (opens in new tab)"), "No preview link present"
      end

      should "indicate that the current user requested a review" do
        assert page.has_text?("You've sent this edition to be reviewed")
      end

      should "not show 'Send to 2i' link as edition already in 'in review' state" do
        visit edition_path(@welsh_edition)
        assert page.has_no_link?("Send to 2i")
      end

      should "not show the 'Resend fact check email' link and text" do
        assert page.has_no_link?("Resend fact check email")
        assert page.has_no_text?("You've requested this edition to be fact checked. We're awaiting a response.")
      end

      should "not show the 'Request amendments' link" do
        assert page.has_no_link?("Request amendments")
      end

      should "not show the 'No changes needed' link" do
        assert page.has_no_link?("No changes needed")
      end

      should "show the 'Skip review' link when the user has the 'skip_review' permission" do
        @welsh_editor.permissions << "skip_review"
        login_as(@welsh_editor)

        visit edition_path(@welsh_edition)

        assert page.has_link?("Skip review")
      end

      should "navigate to 'Skip review' page when 'Skip review' link is clicked" do
        @welsh_editor.permissions << "skip_review"
        login_as(@welsh_editor)

        visit edition_path(@welsh_edition)
        click_link("Skip review")

        assert_current_path skip_review_page_edition_path(@welsh_edition.id)
      end

      should "not show the 'Skip review' link when the user does not have the 'skip_review' permission" do
        assert page.has_no_link?("Skip review")
      end
    end

    context "when viewing a welsh edition as a non-requester" do
      setup do
        @welsh_edition = FactoryBot.create(:edition, :in_review, :welsh, requester: @govuk_requester)
        visit edition_path(@welsh_edition)
      end

      should "display Save button and preview link" do
        assert page.has_button?("Save"), "No save button present"
        assert page.has_link?("Preview (opens in new tab)"), "No preview link present"
      end

      should "indicate which other user requested a review" do
        assert page.has_text?("Stub requester sent this edition to be reviewed")
      end

      should "not show the 'Resend fact check email' link and text" do
        assert page.has_no_link?("Resend fact check email")
        assert page.has_no_text?("You've requested this edition to be fact checked. We're awaiting a response.")
      end

      should "show the 'Request amendments' link" do
        assert page.has_link?("Request amendments")
      end

      should "navigate to the 'Request amendments' page when the link is clicked" do
        click_link("Request amendments")
        assert_current_path request_amendments_page_edition_path(@welsh_edition.id)
      end

      should "show the 'No changes needed' link" do
        assert page.has_link?("No changes needed")
      end

      should "navigate to the 'No changes needed' page when the link is clicked" do
        click_link("No changes needed")
        assert_current_path no_changes_needed_page_edition_path(@welsh_edition.id)
      end

      should "not show the 'Skip review' link" do
        @welsh_editor.permissions << "skip_review"
        login_as(@welsh_editor)

        visit edition_path(@welsh_edition)

        assert page.has_no_link?("Skip review")
      end
    end

    context "when viewing a non-welsh edition" do
      setup do
        @in_review_edition = FactoryBot.create(:edition, :in_review, requester: @govuk_requester)
        visit edition_path(@in_review_edition)
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

      should "not show the 'Request amendments' link" do
        assert page.has_no_link?("Request amendments")
      end

      should "not show the 'No changes needed' link" do
        assert page.has_no_link?("No changes needed")
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
end
