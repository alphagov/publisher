require "test_helper"

class FilteredEditionsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
  end

  context "#my_content" do
    should "render my_content template" do
      get :my_content

      assert_response :ok
      assert_template "filtered_editions/my_content"
    end

    should "display publications that are assigned to the current user" do
      FactoryBot.create(:edition, :draft, title: "Draft edition", assigned_to: @user)
      FactoryBot.create(:edition, :amends_needed, title: "Amends needed edition", assigned_to: @user)
      FactoryBot.create(:edition, :in_review, title: "In review edition", assigned_to: @user)
      FactoryBot.create(:edition, :ready, title: "Ready edition", assigned_to: @user)
      FactoryBot.create(:edition, :fact_check, title: "Fact check edition", assigned_to: @user)
      FactoryBot.create(:edition, :fact_check_received, title: "Fact check received edition", assigned_to: @user)
      FactoryBot.create(:edition, :scheduled_for_publishing, title: "Scheduled for publishing edition", assigned_to: @user)

      get :my_content

      assert_response :ok
      assert_select "tbody tr.govuk-table__row", count: 7
      assert_select "td.govuk-table__cell a", "Draft edition"
      assert_select "td.govuk-table__cell a", "Amends needed edition"
      assert_select "td.govuk-table__cell a", "In review edition"
      assert_select "td.govuk-table__cell a", "Ready edition"
      assert_select "td.govuk-table__cell a", "Fact check edition"
      assert_select "td.govuk-table__cell a", "Fact check received edition"
      assert_select "td.govuk-table__cell a", "Scheduled for publishing edition"
    end

    should "not display publications that are not assigned to the current user" do
      other_user = FactoryBot.create(:user, name: "Other User")
      FactoryBot.create(:edition, title: "Assigned to Other User", assigned_to: other_user)

      get :my_content

      assert_response :ok
      assert_select "p", "There are no publications to display"
      assert_not_select "tbody"
      assert_not_select "td.govuk-table__cell a", "Assigned to Other User"
    end

    should "not display publications that are not in a published or archived state" do
      FactoryBot.create(:edition, :archived, title: "Archived edition", assigned_to: @user)
      FactoryBot.create(:edition, :published, title: "Published edition", assigned_to: @user)

      get :my_content

      assert_response :ok
      assert_select "p", "There are no publications to display"
      assert_not_select "tbody"
      assert_not_select "td.govuk-table__cell a", "Archived edition"
      assert_not_select "td.govuk-table__cell a", "Published edition"
    end

    should "display the correct hint text for a 'Claimed 2i' publication" do
      reviewer = FactoryBot.create(:user, name: "Reviewer")
      FactoryBot.create(:edition, :in_review, title: "Assigned to Stub User", assigned_to: @user, reviewer:)

      get :my_content

      assert_response :ok
      assert_select "td.govuk-table__cell a", "Assigned to Stub User"
      assert_select "td.govuk-table__cell p", "2i reviewer: Reviewer"
    end

    should "display the correct hint text for an 'Unclaimed 2i' publication" do
      FactoryBot.create(:edition, :in_review, title: "Assigned to Stub User", assigned_to: @user, reviewer: nil)

      get :my_content

      assert_response :ok
      assert_select "td.govuk-table__cell a", "Assigned to Stub User"
      assert_select "td.govuk-table__cell p", "Not yet claimed"
    end

    should "display the correct hint text for a 'Scheduled' publication" do
      publish_at = 1.month.from_now
      FactoryBot.create(:edition, :scheduled_for_publishing, publish_at:, title: "Assigned to Stub User", assigned_to: @user)

      get :my_content

      assert_response :ok
      assert_select "td.govuk-table__cell a", "Assigned to Stub User"
      assert_select "td.govuk-table__cell p", "Scheduled for #{publish_at.to_fs(:govuk_date_short)}"
    end

    should "display the correct hint text for a 'Fact check sent' publication" do
      FactoryBot.create(:edition, :fact_check, updated_at: 1.day.ago, title: "Assigned to Stub User", assigned_to: @user)

      get :my_content

      assert_response :ok
      assert_select "td.govuk-table__cell a", "Assigned to Stub User"
      assert_select "td.govuk-table__cell p", "1 day ago"
    end
  end
end
