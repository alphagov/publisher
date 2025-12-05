# frozen_string_literal: true

require_relative "../integration_test_helper"

class PublicationsPageTest < IntegrationTest
  setup do
    @other_user = FactoryBot.create(:user, name: "Other User")
    login_as_govuk_editor
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_edit_phase_3b, true)
  end

  context "my_content page" do
    should "redirect to the my-content page when visiting the root" do
      visit "/"

      assert_current_path my_content_path
    end

    should "display publications assigned to the current user" do
      @draft_edition = FactoryBot.create(:edition, :draft, title: "Draft edition", updated_at: 1.day.ago, assigned_to: @user)
      @amends_needed_edition = FactoryBot.create(:guide_edition, :amends_needed, title: "Amends needed edition", updated_at: 2.days.ago, assigned_to: @user)
      @in_review_edition = FactoryBot.create(:help_page_edition, :in_review, title: "In review edition", updated_at: 3.days.ago, assigned_to: @user)
      @ready_edition = FactoryBot.create(:transaction_edition, :ready, title: "Ready edition", updated_at: 4.days.ago, assigned_to: @user)

      visit my_content_path

      within all(".govuk-table__row")[1] do
        assert page.has_link? "Draft edition", href: edition_path(@draft_edition)
        assert page.has_css?("td strong.govuk-tag.govuk-tag--yellow", text: "Draft")
        assert page.has_css?("td", text: "1 day ago")
        assert page.has_css?("td", text: "Answer")
      end

      within all(".govuk-table__row")[2] do
        assert page.has_link? "Amends needed edition", href: edition_path(@amends_needed_edition)
        assert page.has_css?("td strong.govuk-tag.govuk-tag--red", text: "Amends needed")
        assert page.has_css?("td", text: "2 days ago")
        assert page.has_css?("td", text: "Guide")
      end

      within all(".govuk-table__row")[3] do
        assert page.has_link? "In review edition", href: edition_path(@in_review_edition)
        assert page.has_css?("td strong.govuk-tag.govuk-tag--grey", text: "In review")
        assert page.has_css?("td", text: "3 days ago")
        assert page.has_css?("td", text: "Help page")
      end

      within all(".govuk-table__row")[4] do
        assert page.has_link? "Ready edition", href: edition_path(@ready_edition)
        assert page.has_css?("td strong.govuk-tag.govuk-tag--green", text: "Ready")
        assert page.has_css?("td", text: "4 days ago")
        assert page.has_css?("td", text: "Transaction")
      end
    end

    should "display the correct hint text for a 'Claimed 2i' publication" do
      @claimed_2i_edition = FactoryBot.create(:edition, :in_review, title: "Claimed 2i edition", assigned_to: @user, reviewer: @other_user)

      visit my_content_path

      assert page.has_link? "Claimed 2i edition", href: edition_path(@claimed_2i_edition)
      assert page.has_content? "2i reviewer: Other User"
    end

    should "display the correct hint text for an 'Unclaimed 2i' publication" do
      @unclaimed_2i_edition = FactoryBot.create(:edition, :in_review, title: "Unclaimed 2i edition", assigned_to: @user, reviewer: nil)

      visit my_content_path

      assert page.has_link? "Unclaimed 2i edition", href: edition_path(@unclaimed_2i_edition)
      assert page.has_content? "Not yet claimed"
    end

    should "display the correct hint text for a 'Scheduled' publication" do
      publish_at = 1.month.from_now
      @scheduled_for_publishing_edition = FactoryBot.create(:edition, :scheduled_for_publishing, publish_at:, title: "Scheduled for publishing edition", assigned_to: @user)

      visit my_content_path

      assert page.has_link? "Scheduled for publishing edition", href: edition_path(@scheduled_for_publishing_edition)
      assert page.has_content? "Scheduled for #{publish_at.to_fs(:govuk_date_short)}"
    end

    should "display the correct hint text for a 'Fact check sent' publication" do
      @fact_check_edition = FactoryBot.create(:edition, :fact_check, updated_at: 1.day.ago, title: "Fact check edition", assigned_to: @user)

      visit my_content_path

      assert page.has_link? "Fact check edition", href: edition_path(@fact_check_edition)
      assert page.has_content? "1 day ago"
    end

    should "not display publications not assigned to the current user" do
      @other_user_edition = FactoryBot.create(:edition, :draft, title: "Assigned to Other User edition", assigned_to: @other_user)

      visit my_content_path

      assert page.has_no_link? "Assigned to Other User edition"
    end

    should "not display publications that are in a published or archived state" do
      @published_edition = FactoryBot.create(:edition, :published, title: "Published edition", assigned_to: @user)
      @archived_edition = FactoryBot.create(:edition, :archived, title: "Archived edition", assigned_to: @user)

      visit my_content_path

      assert page.has_no_link? "Published edition"
      assert page.has_no_link? "Archived edition"
    end
  end
end
