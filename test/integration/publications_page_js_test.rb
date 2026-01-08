require "integration_test_helper"

class PublicationsPageJSTest < JavascriptIntegrationTest
  setup do
    @other_user = FactoryBot.create(:user, name: "Other User")
    login_as_govuk_editor
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_edit_phase_3b, true)
  end

  context "2i-queue page" do
    context "English tab" do
      setup do
        @claimed_edition = FactoryBot.create(:answer_edition, :in_review, title: "Claimed edition", assigned_to: @user, review_requested_at: 1.day.ago, reviewer: @other_user)
        @unclaimed_edition = FactoryBot.create(:answer_edition, :in_review, title: "Unclaimed edition", assigned_to: @user, review_requested_at: 1.month.ago)
        @other_user_edition = FactoryBot.create(:guide_edition, :in_review, title: "Other User's edition", assigned_to: @other_user, review_requested_at: 1.week.ago)
        @welsh_edition = FactoryBot.create(:answer_edition, :in_review, :welsh, title: "Welsh edition", assigned_to: @user, review_requested_at: 1.day.ago, reviewer: @other_user)
        @important_note = FactoryBot.create(:action, comment: "This is an important note", edition: @claimed_edition)
        visit "/2i-queue"
      end

      should "display the English tab by default" do
        assert_selector("section.govuk-tabs__panel#english", visible: true)
        assert_selector("section.govuk-tabs__panel--hidden#welsh", visible: false)
        assert_selector("caption", text: "English 3 items")
      end

      should 'display all English publications in the "in_review" state' do
        within find(".govuk-table__row", text: "Claimed edition") do
          assert_link "Claimed edition", href: edition_path(@claimed_edition)
          assert_text "Answer"
          assert_text "Stub User"
          assert_text "1 day"
        end

        within find(".govuk-table__row", text: "Unclaimed edition") do
          assert_link "Unclaimed edition", href: edition_path(@unclaimed_edition)
          assert_text "Answer"
          assert_text "Stub User"
          assert_text "1 month"
        end

        within find(".govuk-table__row", text: "Other User's edition") do
          assert_link "Other User's edition", href: edition_path(@other_user_edition)
          assert_text "Guide"
          assert_text "Other User"
          assert_text "7 days"
        end
      end

      should "display publications ordered by 'review_requested_at' (earliest first)" do
        within find_all(".govuk-table__row")[1] do
          assert_link "Unclaimed edition", href: edition_path(@unclaimed_edition)
        end

        within find_all(".govuk-table__row")[2] do
          assert_link "Other User's edition", href: edition_path(@other_user_edition)
        end

        within find_all(".govuk-table__row")[3] do
          assert_link "Claimed edition", href: edition_path(@claimed_edition)
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
        within find(".govuk-table__row", text: "Other User's edition") do
          assert_button "Claim 2i"
        end
      end

      should "not display Welsh editions" do
        assert_no_link "Welsh edition", href: edition_path(@welsh_edition)
      end
    end

    context "Welsh tab" do
      setup do
        @claimed_edition = FactoryBot.create(:answer_edition, :in_review, :welsh, title: "Claimed edition", assigned_to: @user, review_requested_at: 1.day.ago, reviewer: @other_user)
        @unclaimed_edition = FactoryBot.create(:answer_edition, :in_review, :welsh, title: "Unclaimed edition", assigned_to: @user, review_requested_at: 1.month.ago)
        @other_user_edition = FactoryBot.create(:guide_edition, :in_review, :welsh, title: "Other User's edition", assigned_to: @other_user, review_requested_at: 1.week.ago)
        @english_edition = FactoryBot.create(:answer_edition, :in_review, title: "English edition", assigned_to: @user, review_requested_at: 1.day.ago, reviewer: @other_user)
        @important_note = FactoryBot.create(:action, comment: "This is an important note", edition: @claimed_edition)
        visit "/2i-queue"
        click_link "Welsh", href: "#welsh"
      end

      should "display the Welsh tab when clicked" do
        assert_selector("section.govuk-tabs__panel#welsh", visible: true)
        assert_selector("section.govuk-tabs__panel--hidden#english", visible: false)
        assert_selector("caption", text: "Welsh 3 items")
      end

      should 'display all Welsh publications in the "in_review" state' do
        within find(".govuk-table__row", text: "Claimed edition") do
          assert_link "Claimed edition", href: edition_path(@claimed_edition)
          assert_text "Answer"
          assert_text "Stub User"
          assert_text "1 day"
        end

        within find(".govuk-table__row", text: "Unclaimed edition") do
          assert_link "Unclaimed edition", href: edition_path(@unclaimed_edition)
          assert_text "Answer"
          assert_text "Stub User"
          assert_text "1 month"
        end

        within find(".govuk-table__row", text: "Other User's edition") do
          assert_link "Other User's edition", href: edition_path(@other_user_edition)
          assert_text "Guide"
          assert_text "Other User"
          assert_text "7 days"
        end
      end

      should "display publications ordered by 'review_requested_at' (earliest first)" do
        within find_all(".govuk-table__row")[1] do
          assert_link "Unclaimed edition", href: edition_path(@unclaimed_edition)
        end

        within find_all(".govuk-table__row")[2] do
          assert_link "Other User's edition", href: edition_path(@other_user_edition)
        end

        within find_all(".govuk-table__row")[3] do
          assert_link "Claimed edition", href: edition_path(@claimed_edition)
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
        within find(".govuk-table__row", text: "Other User's edition") do
          assert_button "Claim 2i"
        end
      end

      should "not display English editions" do
        assert_no_link "English edition", href: edition_path(@english_edition)
      end
    end
  end
end
