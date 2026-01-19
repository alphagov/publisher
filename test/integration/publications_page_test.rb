# frozen_string_literal: true

require_relative "../integration_test_helper"

class PublicationsPageTest < IntegrationTest
  setup do
    @other_user = FactoryBot.create(:user, name: "Other User")
    login_as_govuk_editor
    @test_strategy = Flipflop::FeatureSet.current.test!
    @test_strategy.switch!(:design_system_edit_phase_3b, true)
  end

  context "my_content page" do
    should "redirect to the my-content page when visiting the root" do
      visit "/"

      assert_current_path my_content_path
    end

    [[true, "In 2i"], [false, "In review"]].each do |toggle_value, in_review_state_label|
      context "when the 'rename_edition_states' feature toggle is '#{toggle_value}'" do
        setup do
          @test_strategy.switch!(:rename_edition_states, toggle_value)
        end

        should "display publications assigned to the current user" do
          @draft_edition = FactoryBot.create(:edition, :draft, title: "Draft edition", updated_at: 1.day.ago, assigned_to: @user)
          @amends_needed_edition = FactoryBot.create(:guide_edition, :amends_needed, title: "Amends needed edition", updated_at: 2.days.ago, assigned_to: @user)
          @in_review_edition = FactoryBot.create(:help_page_edition, :in_review, title: "In review edition", updated_at: 3.days.ago, assigned_to: @user)
          @ready_edition = FactoryBot.create(:transaction_edition, :ready, title: "Ready edition", updated_at: 4.days.ago, assigned_to: @user)

          visit my_content_path

          within find(".govuk-table__row", text: "Draft edition") do
            assert_link "Draft edition", href: edition_path(@draft_edition)
            assert_css ".govuk-tag--yellow", text: "Draft"
            assert_text "1 day ago"
            assert_text "Answer"
          end

          within find(".govuk-table__row", text: "Amends needed edition") do
            assert_link "Amends needed edition", href: edition_path(@amends_needed_edition)
            assert page.has_css?(".govuk-tag--red", text: "Amends needed")
            assert_text "2 days ago"
            assert_text "Guide"
          end

          within find(".govuk-table__row", text: "In review edition") do
            assert_link "In review edition", href: edition_path(@in_review_edition)
            assert page.has_css?(".govuk-tag--grey", text: in_review_state_label)
            assert_text "3 days ago"
            assert_text "Help page"
          end

          within find(".govuk-table__row", text: "Ready edition") do
            assert_link "Ready edition", href: edition_path(@ready_edition)
            assert page.has_css?(".govuk-tag--green", text: "Ready")
            assert_text "4 days ago"
            assert_text "Transaction"
          end
        end
      end
    end

    should "display the correct hint text for a 'Claimed 2i' publication" do
      @claimed_2i_edition = FactoryBot.create(:edition, :in_review, title: "Claimed 2i edition", assigned_to: @user, reviewer: @other_user)

      visit my_content_path

      within find(".govuk-table__row", text: "Claimed 2i edition") do
        assert_link "Claimed 2i edition", href: edition_path(@claimed_2i_edition)
        assert_text "2i reviewer: Other User"
      end
    end

    should "display the correct hint text for an 'Unclaimed 2i' publication" do
      @unclaimed_2i_edition = FactoryBot.create(:edition, :in_review, title: "Unclaimed 2i edition", assigned_to: @user, reviewer: nil)

      visit my_content_path

      within find(".govuk-table__row", text: "Unclaimed 2i edition") do
        assert_link "Unclaimed 2i edition", href: edition_path(@unclaimed_2i_edition)
        assert_text "Not yet claimed"
      end
    end

    should "display the correct hint text for a 'Scheduled' publication" do
      publish_at = 1.month.from_now
      @scheduled_for_publishing_edition = FactoryBot.create(:edition, :scheduled_for_publishing, publish_at:, title: "Scheduled for publishing edition", assigned_to: @user)

      visit my_content_path

      within find(".govuk-table__row", text: "Scheduled for publishing edition") do
        assert_link "Scheduled for publishing edition", href: edition_path(@scheduled_for_publishing_edition)
        assert_text "Scheduled for #{publish_at.to_fs(:govuk_date_short)}"
      end
    end

    should "display the correct hint text for a 'Fact check sent' publication" do
      @fact_check_edition = FactoryBot.create(:edition, :fact_check, updated_at: 2.days.ago, title: "Edition 1", assigned_to: @user)
      @fact_check_edition_2 = FactoryBot.create(:edition, :fact_check, updated_at: 3.hours.ago, title: "Edition 2", assigned_to: @user)

      visit my_content_path

      within find(".govuk-table__row", text: "Edition 1") do
        assert_link "Edition 1", href: edition_path(@fact_check_edition)
        assert_text "Sent 2 days ago"
      end

      within find(".govuk-table__row", text: "Edition 2") do
        assert_link "Edition 2", href: edition_path(@fact_check_edition_2)
        assert_text "Sent about 3 hours ago"
      end
    end

    should "not display publications not assigned to the current user" do
      @other_user_edition = FactoryBot.create(:edition, :draft, title: "Assigned to Other User edition", assigned_to: @other_user)

      visit my_content_path

      assert_text "You do not have any content assigned to you."
      assert_no_link "Assigned to Other User edition"
    end

    should "not display publications that are in a published or archived state" do
      @published_edition = FactoryBot.create(:edition, :published, title: "Published edition", assigned_to: @user)
      @archived_edition = FactoryBot.create(:edition, :archived, title: "Archived edition", assigned_to: @user)

      visit my_content_path

      assert_text "You do not have any content assigned to you."
      assert_no_link "Published edition"
      assert_no_link "Archived edition"
    end
  end

  context "2i-queue page" do
    setup do
      @claimed_edition = FactoryBot.create(:answer_edition, :in_review, title: "Claimed edition", assigned_to: @user, review_requested_at: 1.day.ago, reviewer: @other_user)
      @unclaimed_edition = FactoryBot.create(:guide_edition, :in_review, title: "Unclaimed edition", assigned_to: @user, review_requested_at: 1.month.ago)
      @other_user_edition = FactoryBot.create(:answer_edition,
                                              :in_review,
                                              title: "Other User's edition (English)",
                                              assigned_to: @other_user,
                                              review_requested_at: 1.week.ago,
                                              actions: [FactoryBot.create(:action, request_type: Action::REQUEST_REVIEW)])
      @welsh_edition = FactoryBot.create(:answer_edition, :in_review, :welsh, title: "Welsh edition", assigned_to: @user, review_requested_at: 1.day.ago, reviewer: @other_user)
      @other_user_welsh_edition = FactoryBot.create(:answer_edition, :in_review, :welsh, title: "Other User's edition (Welsh)", assigned_to: @user, review_requested_at: 1.week.ago)
      @important_note = FactoryBot.create(:action, comment: "This is an important note", edition: @claimed_edition)
      visit "/2i-queue"
    end

    should "display all English publications in the 'in_review' state" do
      within find("section#english") do
        within find(".govuk-table__row", text: "Claimed edition") do
          assert_link "Claimed edition", href: edition_path(@claimed_edition)
          assert_text "Answer"
          assert_text "Stub User"
          assert_text "1 day"
        end

        within find(".govuk-table__row", text: "Unclaimed edition") do
          assert_link "Unclaimed edition", href: edition_path(@unclaimed_edition)
          assert_text "Guide"
          assert_text "Stub User"
          assert_text "1 month"
        end

        within find(".govuk-table__row", text: "Other User's edition (English)") do
          assert_link "Other User's edition (English)", href: edition_path(@other_user_edition)
          assert_text "Answer"
          assert_text "Other User"
          assert_text "7 days"
        end
      end
    end

    should "display all Welsh publications in the 'in_review' state" do
      within find("section#welsh") do
        within find(".govuk-table__row", text: "Welsh edition") do
          assert_link "Welsh edition", href: edition_path(@welsh_edition)
          assert_text "Answer"
          assert_text "Stub User"
          assert_text "1 day"
        end

        within find(".govuk-table__row", text: "Other User's edition (Welsh)") do
          assert_link "Other User's edition (Welsh)", href: edition_path(@other_user_welsh_edition)
          assert_text "Answer"
          assert_text "Stub User"
          assert_text "7 days"
        end
      end
    end

    should "display English publications ordered by 'review_requested_at' (earliest first)" do
      within find("section#english") do
        within find_all(".govuk-table__row")[1] do
          assert_link "Unclaimed edition", href: edition_path(@unclaimed_edition)
        end

        within find_all(".govuk-table__row")[2] do
          assert_link "Other User's edition (English)", href: edition_path(@other_user_edition)
        end

        within find_all(".govuk-table__row")[3] do
          assert_link "Claimed edition", href: edition_path(@claimed_edition)
        end
      end
    end

    should "display Welsh publications ordered by 'review_requested_at' (earliest first)" do
      within find("section#welsh") do
        within find_all(".govuk-table__row")[1] do
          assert_link "Other User's edition (Welsh)", href: edition_path(@other_user_welsh_edition)
        end

        within find_all(".govuk-table__row")[2] do
          assert_link "Welsh edition", href: edition_path(@welsh_edition)
        end
      end
    end

    should "display important notes" do
      within find(".govuk-table__row", text: "Claimed edition") do
        assert_text "This is an important note"
      end
    end

    should "display claimed editions assigned to the user with the reviewer name" do
      within find(".govuk-table__row", text: "Claimed edition") do
        assert_text "Other User"
      end
    end

    should "display unclaimed editions assigned to the user with the 'Not yet claimed' text" do
      within find(".govuk-table__row", text: "Unclaimed edition") do
        assert_text "Not yet claimed"
      end
    end

    should "display claimed editions assigned to other users with the 'Claim 2i' button" do
      within find(".govuk-table__row", text: "Other User's edition (English)") do
        assert_button "Claim 2i"
      end
    end

    should "allow user to claim an edition via the 'Claim 2i' button" do
      within find(".govuk-table__row", text: "Other User's edition (English)") do
        click_button "Claim 2i"
      end

      assert_current_path edition_path(@other_user_edition)
      assert_text "You are the reviewer of this answer."
      within find(".govuk-summary-list__row", text: "2i reviewer") do
        assert_selector(".govuk-summary-list__value", text: @user.name)
      end
    end
  end

  context "find_content page" do
    should "redirect to the find-content page when find content link in the navigation bar is clicked" do
      visit "/find-content"

      assert_current_path find_content_path
    end

    [[true, "In 2i"], [false, "In review"]].each do |toggle_value, in_review_state_label|
      context "when the 'rename_edition_states' feature toggle is '#{toggle_value}'" do
        should "display publications data for find content page" do
          @test_strategy.switch!(:rename_edition_states, toggle_value)
          @draft_edition = FactoryBot.create(:edition, :draft, title: "Draft edition", updated_at: 1.day.ago, assigned_to: @user)
          @amends_needed_edition = FactoryBot.create(:guide_edition, :amends_needed, title: "Amends needed edition", updated_at: 2.days.ago, assigned_to: @other_user)
          @in_review_edition = FactoryBot.create(:help_page_edition, :in_review, title: "In review edition", updated_at: 3.days.ago, assigned_to: @user)
          @ready_edition = FactoryBot.create(:transaction_edition, :ready, title: "Ready edition", updated_at: 4.days.ago, assigned_to: @other_user)

          visit find_content_path

          within find(".govuk-table__row", text: "Draft edition") do
            assert_link "Draft edition", href: edition_path(@draft_edition)
            assert_css ".govuk-tag--yellow", text: "Draft"
            assert_text "1 day ago"
            assert_text "Answer"
          end

          within find(".govuk-table__row", text: "Amends needed edition") do
            assert_link "Amends needed edition", href: edition_path(@amends_needed_edition)
            assert page.has_css?(".govuk-tag--red", text: "Amends needed")
            assert_text "2 days ago"
            assert_text "Guide"
          end

          within find(".govuk-table__row", text: "In review edition") do
            assert_link "In review edition", href: edition_path(@in_review_edition)
            assert page.has_css?(".govuk-tag--grey", text: in_review_state_label)
            assert_text "3 days ago"
            assert_text "Help page"
          end

          within find(".govuk-table__row", text: "Ready edition") do
            assert_link "Ready edition", href: edition_path(@ready_edition)
            assert page.has_css?(".govuk-tag--green", text: "Ready")
            assert_text "4 days ago"
            assert_text "Transaction"
          end
        end
      end
    end

    should "display the correct hint text with title" do
      @draft_edition = FactoryBot.create(:edition, :draft, title: "Draft edition", updated_at: 1.day.ago, assigned_to: @user)

      visit find_content_path

      within find(".govuk-table__row", text: "Draft edition") do
        assert page.has_css?(".govuk-hint", text: "/slug-1")
      end
    end

    should "not display publications that are in an archived state" do
      @archived_edition = FactoryBot.create(:edition, :archived, title: "Archived edition", assigned_to: @user)

      visit find_content_path

      assert_no_link "Archived edition"
    end
  end

  context "fact-check page" do
    setup do
      @returned_edition = FactoryBot.create(:edition, :fact_check_received, title: "Returned edition", assigned_to: @user, received_at: 1.day.ago)
      @other_user_returned_edition = FactoryBot.create(:edition, :fact_check_received, title: "Other User's edition", assigned_to: @other_user, received_at: 1.month.ago)
      @recent_returned_edition = FactoryBot.create(:edition, :fact_check_received, title: "Recent returned edition", assigned_to: @user, received_at: 1.hour.ago)
      @awaiting_response_edition = FactoryBot.create(:edition, :fact_check, title: "Awaiting response edition", assigned_to: @user, sent_out_at: 1.week.ago)
      @other_user_awaiting_response_edition = FactoryBot.create(:edition, :fact_check, title: "Other User's edition", assigned_to: @other_user, sent_out_at: 1.month.ago)
      @recent_awaiting_response_edition = FactoryBot.create(:edition, :fact_check, title: "Recent awaiting response edition", assigned_to: @user, sent_out_at: 1.hour.ago)

      visit "/fact-check"
    end

    should "display all publications in the 'fact_check_received' state" do
      within find("section#received") do
        within find(".govuk-table__row", text: "Returned edition") do
          assert_link "Returned edition", href: edition_path(@returned_edition)
          assert_link "View response", href: history_edition_path(@returned_edition, anchor: "edition-#{@returned_edition.history.first.version_number}")
          assert_text "1 day ago"
          assert_text "Stub User"
          assert_text "Answer"
        end

        within find(".govuk-table__row", text: "Other User's edition") do
          assert_link "Other User's edition", href: edition_path(@other_user_returned_edition)
          assert_link "View response", href: history_edition_path(@other_user_returned_edition, anchor: "edition-#{@other_user_returned_edition.history.first.version_number}")
          assert_text "1 month ago"
          assert_text "Other User"
          assert_text "Answer"
        end

        within find(".govuk-table__row", text: "Recent returned edition") do
          assert_link "Recent returned edition", href: edition_path(@recent_returned_edition)
          assert_link "View response", href: history_edition_path(@recent_returned_edition, anchor: "edition-#{@recent_returned_edition.history.first.version_number}")
          assert_text "1 hour ago"
          assert_text "Stub User"
          assert_text "Answer"
        end
      end
    end

    should "display 'fact_check_received' publications ordered by the 'receive_fact_check' action creation date (most recent first)" do
      within find("section#received") do
        within find_all(".govuk-table__row")[1] do
          assert_link "Recent returned edition", href: edition_path(@recent_returned_edition)
        end

        within find_all(".govuk-table__row")[2] do
          assert_link "Returned edition", href: edition_path(@returned_edition)
        end

        within find_all(".govuk-table__row")[3] do
          assert_link "Other User's edition", href: edition_path(@other_user_returned_edition)
        end
      end
    end

    should "display all publications in the 'fact_check' state" do
      within find("section#sent_out") do
        within find(".govuk-table__row", text: "Awaiting response edition") do
          assert_link "Awaiting response edition", href: edition_path(@awaiting_response_edition)
          assert_text "7 days ago"
          assert_text "Stub User"
          assert_text "Answer"
        end

        within find(".govuk-table__row", text: "Other User's edition") do
          assert_link "Other User's edition", href: edition_path(@other_user_awaiting_response_edition)
          assert_text "1 month ago"
          assert_text "Other User"
          assert_text "Answer"
        end

        within find(".govuk-table__row", text: "Recent awaiting response edition") do
          assert_link "Recent awaiting response edition", href: edition_path(@recent_awaiting_response_edition)
          assert_text "1 hour ago"
          assert_text "Stub User"
          assert_text "Answer"
        end
      end
    end

    should "display 'fact_check' publications ordered by 'last_fact_checked_at' (most recent first)" do
      within find("section#sent_out") do
        within find_all(".govuk-table__row")[1] do
          assert_link "Recent awaiting response edition", href: edition_path(@recent_awaiting_response_edition)
        end

        within find_all(".govuk-table__row")[2] do
          assert_link "Awaiting response edition", href: edition_path(@awaiting_response_edition)
        end

        within find_all(".govuk-table__row")[3] do
          assert_link "Other User's edition", href: edition_path(@other_user_awaiting_response_edition)
        end
      end
    end
  end
end
