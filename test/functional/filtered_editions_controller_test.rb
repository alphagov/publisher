require "test_helper"

class FilteredEditionsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
    @other_user = FactoryBot.create(:user, name: "Other User")
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
      assert_select "th.govuk-table__header a", "Draft edition"
      assert_select "th.govuk-table__header a", "Amends needed edition"
      assert_select "th.govuk-table__header a", "In review edition"
      assert_select "th.govuk-table__header a", "Ready edition"
      assert_select "th.govuk-table__header a", "Fact check edition"
      assert_select "th.govuk-table__header a", "Fact check received edition"
      assert_select "th.govuk-table__header a", "Scheduled for publishing edition"
    end

    should "not display publications that are not assigned to the current user" do
      FactoryBot.create(:edition, title: "Assigned to Other User", assigned_to: @other_user)

      get :my_content

      assert_response :ok
      assert_select "p.govuk-body", "You do not have any content assigned to you."
      assert_not_select "tbody"
      assert_not_select "th.govuk-table__header a", "Assigned to Other User"
    end

    should "not display publications that are in a published or archived state" do
      FactoryBot.create(:edition, :archived, title: "Archived edition", assigned_to: @user)
      FactoryBot.create(:edition, :published, title: "Published edition", assigned_to: @user)

      get :my_content

      assert_response :ok
      assert_select "p.govuk-body", "You do not have any content assigned to you."
      assert_not_select "tbody"
      assert_not_select "th.govuk-table__header a", "Archived edition"
      assert_not_select "th.govuk-table__header a", "Published edition"
    end

    should "display the correct hint text for a 'Claimed 2i' publication" do
      reviewer = FactoryBot.create(:user, name: "Reviewer")
      FactoryBot.create(:edition, :in_review, title: "Assigned to Stub User", assigned_to: @user, reviewer:)

      get :my_content

      assert_response :ok
      assert_select "th.govuk-table__header a", "Assigned to Stub User"
      assert_select "th.govuk-table__header .govuk-hint", "2i reviewer: Reviewer"
    end

    should "display the correct hint text for an 'Unclaimed 2i' publication" do
      FactoryBot.create(:edition, :in_review, title: "Assigned to Stub User", assigned_to: @user, reviewer: nil)

      get :my_content

      assert_response :ok
      assert_select "th.govuk-table__header a", "Assigned to Stub User"
      assert_select "th.govuk-table__header .govuk-hint", "Not yet claimed"
    end

    should "display the correct hint text for a 'Scheduled' publication" do
      publish_at = 1.month.from_now
      FactoryBot.create(:edition, :scheduled_for_publishing, publish_at:, title: "Assigned to Stub User", assigned_to: @user)

      get :my_content

      assert_response :ok
      assert_select "th.govuk-table__header a", "Assigned to Stub User"
      assert_select "th.govuk-table__header .govuk-hint", "Scheduled for #{publish_at.to_fs(:govuk_date_short)}"
    end

    should "display the correct hint text for a 'Fact check sent' publication" do
      FactoryBot.create(:edition, :fact_check, updated_at: 1.day.ago, title: "Assigned to Stub User", assigned_to: @user)

      get :my_content

      assert_response :ok
      assert_select "th.govuk-table__header a", "Assigned to Stub User"
      assert_select "th.govuk-table__header .govuk-hint", "Sent 1 day ago"
    end
  end

  context "#two_eye_queue" do
    should "render two_eye_queue template" do
      get :two_eye_queue

      assert_response :ok
      assert_template "filtered_editions/two_eye_queue"
      assert_select "section.govuk-tabs__panel#english"
      assert_select "section.govuk-tabs__panel#welsh"
    end

    should "render the English and Welsh tabs" do
      get :two_eye_queue

      assert_response :ok
      assert_select "section.govuk-tabs__panel#english"
      assert_select "section.govuk-tabs__panel#welsh"
    end

    should "render publications that are in the 'in_review' state" do
      FactoryBot.create(:edition, :in_review, title: "English edition assigned to user", assigned_to: @user)
      FactoryBot.create(:edition, :in_review, title: "English edition assigned to other user", assigned_to: @other_user)
      FactoryBot.create(:edition, :in_review, :welsh, title: "Welsh edition assigned to user", assigned_to: @user)
      FactoryBot.create(:edition, :in_review, :welsh, title: "Welsh edition assigned to other user", assigned_to: @other_user)

      get :two_eye_queue

      assert_response :ok
      assert_select "section.govuk-tabs__panel#english" do
        assert_select "th.govuk-table__header a", "English edition assigned to user"
        assert_select "th.govuk-table__header a", "English edition assigned to other user"
      end

      assert_select "section.govuk-tabs__panel#welsh" do
        assert_select "th.govuk-table__header a", "Welsh edition assigned to user"
        assert_select "th.govuk-table__header a", "Welsh edition assigned to other user"
      end
    end

    %i[draft amends_needed ready fact_check fact_check_received scheduled_for_publishing archived published].each do |state|
      should "not render publications that are in the '#{state}' state" do
        FactoryBot.create(:edition, state, title: state.to_s, assigned_to: @user)

        get :two_eye_queue

        assert_response :ok
        assert_select "span.item-count", "0 items"
        assert_not_select "tbody"
        assert_not_select "th.govuk-table__header a", state.to_s
      end
    end

    context "when the edition has no 2i reviewer" do
      should "render the 'Claim 2i' button when the edition is not assigned to the user" do
        FactoryBot.create(:edition, :in_review, title: "Unclaimed English edition", assigned_to: @other_user)
        FactoryBot.create(:edition, :in_review, :welsh, title: "Unclaimed Welsh edition", assigned_to: @other_user)

        get :two_eye_queue

        assert_select "section.govuk-tabs__panel#english" do
          assert_select "td.govuk-table__cell button", "Claim 2i"
        end

        assert_select "section.govuk-tabs__panel#welsh" do
          assert_select "td.govuk-table__cell button", "Claim 2i"
        end
      end

      should "not display the 'Claim 2i' button when the edition is assigned to the user" do
        FactoryBot.create(:edition, :in_review, title: "Unclaimed English edition", assigned_to: @user)
        FactoryBot.create(:edition, :in_review, :welsh, title: "Unclaimed Welsh edition", assigned_to: @user)

        get :two_eye_queue

        assert_select "section.govuk-tabs__panel#english" do
          assert_not_select "td.govuk-table__cell button", "Claim 2i"
          assert_select "td.govuk-table__cell", "Not yet claimed"
        end

        assert_select "section.govuk-tabs__panel#welsh" do
          assert_not_select "td.govuk-table__cell button", "Claim 2i"
          assert_select "td.govuk-table__cell", "Not yet claimed"
        end
      end
    end

    context "when the edition has a 2i reviewer" do
      should "display the 2i reviewer name" do
        FactoryBot.create(:edition, :in_review, title: "Unclaimed English edition", assigned_to: @user, reviewer: @other_user)
        FactoryBot.create(:edition, :in_review, :welsh, title: "Unclaimed Welsh edition", assigned_to: @user, reviewer: @other_user)

        get :two_eye_queue

        assert_select "section.govuk-tabs__panel#english" do
          assert_select "td.govuk-table__cell", "Other User"
        end

        assert_select "section.govuk-tabs__panel#welsh" do
          assert_select "td.govuk-table__cell", "Other User"
        end
      end
    end
  end

  context "#find_content" do
    should "render find_content template" do
      get :find_content

      assert_response :ok
      assert_template "filtered_editions/find_content"
    end

    should "display publications data on find content page" do
      FactoryBot.create(:edition, :draft, title: "Draft edition", assigned_to: @user)
      FactoryBot.create(:edition, :amends_needed, title: "Amends needed edition", assigned_to: @user)
      FactoryBot.create(:edition, :in_review, title: "In review edition", assigned_to: @user)
      FactoryBot.create(:edition, :ready, title: "Ready edition", assigned_to: @other_user)
      FactoryBot.create(:edition, :fact_check, title: "Fact check edition", assigned_to: @user)
      FactoryBot.create(:edition, :fact_check_received, title: "Fact check received edition", assigned_to: @user)
      FactoryBot.create(:edition, :scheduled_for_publishing, title: "Scheduled for publishing edition", assigned_to: @other_user)

      get :find_content

      assert_response :ok
      assert_select "tbody tr.govuk-table__row", count: 7
      assert_select "th.govuk-table__header a", "Draft edition"
      assert_select "th.govuk-table__header a", "Amends needed edition"
      assert_select "th.govuk-table__header a", "In review edition"
      assert_select "th.govuk-table__header a", "Ready edition"
      assert_select "th.govuk-table__header a", "Fact check edition"
      assert_select "th.govuk-table__header a", "Fact check received edition"
      assert_select "th.govuk-table__header a", "Scheduled for publishing edition"
    end

    should "not display publications that are in an archived state" do
      FactoryBot.create(:edition, :archived, title: "Archived edition", assigned_to: @user)

      get :find_content

      assert_response :ok
      assert_not_select "th.govuk-table__header a", "Archived edition"
    end

    should "display the correct hint text with title" do
      FactoryBot.create(:edition, :draft, title: "Draft edition", assigned_to: @user)

      get :find_content

      assert_response :ok
      assert_select "th.govuk-table__header a", "Draft edition"
      assert_select "th.govuk-table__header .govuk-body", "/slug-1"
    end

    should "display the total count of editions" do
      FactoryBot.create(:edition, :draft, title: "Draft edition1", assigned_to: @user)
      FactoryBot.create(:edition, :draft, title: "Draft edition2", assigned_to: @user)

      get :find_content

      assert_response :ok
      assert_select ".item-count", "2 items"
    end

    should "display the total count as zero when no edition is present" do
      get :find_content

      assert_response :ok
      assert_select ".govuk-body", "0 items"
    end

    should "show the first page of find content when no page is specified" do
      FactoryBot.create_list(
        :edition, FilteredEditionsPresenter::ITEMS_PER_PAGE + 1, assigned_to: @user
      )

      get :find_content

      assert_response :ok
      assert_select ".item-count", "#{FilteredEditionsPresenter::ITEMS_PER_PAGE + 1} items"
      assert_select "th.govuk-table__header a", FilteredEditionsPresenter::ITEMS_PER_PAGE
    end

    should "show the specified page of find content" do
      FactoryBot.create_list(
        :edition, FilteredEditionsPresenter::ITEMS_PER_PAGE + 1, assigned_to: @user
      )

      get :find_content, params: { page: 2 }

      assert_response :ok
      assert_select ".item-count", "#{FilteredEditionsPresenter::ITEMS_PER_PAGE + 1} items"
      assert_select "tbody tr.govuk-table__row", 1
    end

    context "find content filter" do
      should "show filter fields on find content page when loaded" do
        get :find_content

        assert_response :ok
        assert_select ".govuk-input[name='search_text']"
        assert_select ".govuk-select#states_filter"
        assert_select ".govuk-select#assignee_filter"
        assert_select ".govuk-select#content_type_filter"
        assert_select ".govuk-button", text: "Apply filters"
        assert_not_select ".govuk-link", text: "Clear filters"
      end

      should "filter publications data by state" do
        FactoryBot.create(:guide_edition, state: "draft", assigned_to: @user)
        FactoryBot.create(:edition, state: "ready", assigned_to: @user)

        get :find_content, params: { states_filter: "draft" }

        assert_response :ok
        assert_select ".govuk-link", text: "Clear filters"
        assert_select "tbody tr.govuk-table__row", count: 1
        assert_select ".govuk-table__cell", "Draft"
      end

      should "filter publications data by content type" do
        FactoryBot.create(:guide_edition, assigned_to: @user)
        FactoryBot.create(:completed_transaction_edition, assigned_to: @user)

        get :find_content, params: { content_type_filter: "guide" }

        assert_response :ok
        assert_select ".govuk-link", text: "Clear filters"
        assert_select "tbody tr.govuk-table__row", count: 1
        assert_select ".govuk-table__cell", "Guide"
      end

      should "filter publications data by title text" do
        FactoryBot.create(:guide_edition, title: "How to train your dragon", assigned_to: @user)
        FactoryBot.create(:guide_edition, title: "What to do in the event of a zombie apocalypse", assigned_to: @user)

        get :find_content, params: { search_text: "zombie" }

        assert_response :ok
        assert_select ".govuk-link", text: "Clear filters"
        assert_select "tbody tr.govuk-table__row", count: 1
        assert_select ".govuk-link", /What to do in the event of a zombie apocalypse/
      end

      should "filter publications data by assignee" do
        anna = FactoryBot.create(:user, name: "Anna")
        FactoryBot.create(:guide_edition, assigned_to: anna)
        FactoryBot.create(:guide_edition)

        get :find_content, params: { assignee_filter: anna.id }

        assert_response :ok
        assert_select "tbody tr.govuk-table__row", count: 1
        assert_select "td.govuk-table__cell", "Anna"
      end
    end
  end

  context "#fact_check" do
    should "render fact_check template" do
      get :fact_check

      assert_response :ok
      assert_template "filtered_editions/fact_check"
    end

    should "render the 'Returned' and 'Awaiting response' tabs" do
      get :fact_check

      assert_response :ok
      assert_select "section.govuk-tabs__panel#received"
      assert_select "section.govuk-tabs__panel#sent_out"
    end

    should "render publications that are in the 'fact_check_received' state" do
      FactoryBot.create(:edition, :fact_check_received, title: "Returned edition", assigned_to: @user, received_at: 1.day.ago)
      FactoryBot.create(:edition, :fact_check_received, title: "Other User's edition", assigned_to: @other_user, received_at: 1.month.ago)

      get :fact_check

      assert_response :ok
      assert_select "section.govuk-tabs__panel#received" do
        assert_select "th.govuk-table__header a", "Returned edition"
        assert_select "th.govuk-table__header a", "Other User's edition"
      end
    end

    should "render publications that are in the 'fact_check' state" do
      FactoryBot.create(:edition, :fact_check, title: "Awaiting response edition", assigned_to: @user, sent_out_at: 1.day.ago)
      FactoryBot.create(:edition, :fact_check, title: "Other User's edition", assigned_to: @other_user, sent_out_at: 1.month.ago)

      get :fact_check

      assert_response :ok
      assert_select "section.govuk-tabs__panel#sent_out" do
        assert_select "th.govuk-table__header a", "Awaiting response edition"
        assert_select "th.govuk-table__header a", "Other User's edition"
      end
    end

    %i[draft amends_needed ready in_review scheduled_for_publishing archived published].each do |state|
      should "not render publications that are in the '#{state}' state" do
        FactoryBot.create(:edition, state, title: state.to_s, assigned_to: @user)

        get :fact_check

        assert_response :ok
        assert_select "span.item-count", "0 items"
        assert_not_select "tbody"
        assert_not_select "th.govuk-table__header a", state.to_s
      end
    end
  end
end
