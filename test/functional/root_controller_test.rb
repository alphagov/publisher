require "test_helper"

class RootControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
  end

  context "#index" do
    should "render index template" do
      get :index

      assert_response :ok
      assert_template "root/index"
    end

    should "default all state filter checkboxes to unchecked" do
      get :index

      assert_select "input.govuk-checkboxes__input", 9
      assert_select "input.govuk-checkboxes__input" do
        assert_select "[checked]", false
      end

      assert_select "input.govuk-checkboxes__input[value='draft']"
      assert_select "input.govuk-checkboxes__input[value='amends_needed']"
      assert_select "input.govuk-checkboxes__input[value='in_review']"
      assert_select "input.govuk-checkboxes__input[value='fact_check']"
      assert_select "input.govuk-checkboxes__input[value='fact_check_received']"
      assert_select "input.govuk-checkboxes__input[value='ready']"
      assert_select "input.govuk-checkboxes__input[value='scheduled_for_publishing']"
      assert_select "input.govuk-checkboxes__input[value='published']"
      assert_select "input.govuk-checkboxes__input[value='archived']"
    end

    should "default the applied state filters" do
      FactoryBot.create(:edition, state: "draft", assigned_to: @user)
      FactoryBot.create(:edition, state: "in_review", review_requested_at: 1.hour.ago, assigned_to: @user)
      FactoryBot.create(:edition, state: "amends_needed", assigned_to: @user)
      fact_check_edition = FactoryBot.create(:edition, state: "fact_check", title: "Check yo fax", assigned_to: @user)
      fact_check_edition.new_action(FactoryBot.create(:user), "send_fact_check")
      FactoryBot.create(:edition, state: "fact_check_received", assigned_to: @user)
      FactoryBot.create(:edition, state: "ready", assigned_to: @user)
      FactoryBot.create(:edition, state: "scheduled_for_publishing", publish_at: Time.zone.now + 1.hour, assigned_to: @user)
      FactoryBot.create(:edition, state: "published", assigned_to: @user)
      FactoryBot.create(:edition, state: "archived", assigned_to: @user)

      get :index

      assert_select "p.publications-table__heading", "9 document(s)"
      assert_select "span.govuk-tag--draft", "Draft"
      assert_select "span.govuk-tag--in_review", "In review"
      assert_select "span.govuk-tag--amends_needed", "Amends needed"
      assert_select "span.govuk-tag--fact_check", "Fact check"
      assert_select "span.govuk-tag--fact_check_received", "Fact check received"
      assert_select "span.govuk-tag--ready", "Ready"
      assert_select "span.govuk-tag--scheduled_for_publishing", "Scheduled for publishing"
      assert_select "span.govuk-tag--published", "Published"
      assert_select "span.govuk-tag--archived", "Archived"
    end

    should "filter publications by state" do
      FactoryBot.create(:guide_edition, state: "draft", assigned_to: @user)
      FactoryBot.create(:guide_edition, state: "published", assigned_to: @user)
      FactoryBot.create(:edition, state: "ready", assigned_to: @user)

      get :index, params: { states_filter: %w[draft published] }

      assert_response :ok
      assert_select "p.publications-table__heading", "2 document(s)"
      assert_select "td.govuk-table__cell", "Draft"
      assert_select "td.govuk-table__cell", "Published"
    end

    should "default the assignee to the current user" do
      get :index

      assert_response :ok
      assert_select "#assignee_filter > option[value='#{@user.id}'][selected]"
    end

    should "default filtering to publications assigned to the current user" do
      anna = FactoryBot.create(:user, name: "Anna")
      FactoryBot.create(:edition, title: "Assigned to Anna", assigned_to: anna)
      FactoryBot.create(:edition, title: "Assigned to Stub User", assigned_to: @user)

      get :index

      assert_response :ok
      assert_select "p.publications-table__heading", "1 document(s)"
      assert_select "td.govuk-table__cell", "Stub User"
    end

    should "filter publications by assignee in the session" do
      anna = FactoryBot.create(:user, name: "Anna")
      @request.session[:assignee_filter] = anna.id.to_s

      get :index

      assert_response :ok
      assert_select "#assignee_filter > option[value='#{anna.id}'][selected]"
    end

    should "filter publications by assignee parameter" do
      anna = FactoryBot.create(:user, name: "Anna")
      FactoryBot.create(:guide_edition, assigned_to: anna)
      FactoryBot.create(:guide_edition)

      get :index, params: { assignee_filter: anna.id }

      assert_response :ok
      assert_select "p.publications-table__heading", "1 document(s)"
      assert_select "td.govuk-table__cell", "Anna"
    end

    should "store the assignee parameter value in the session" do
      anna = FactoryBot.create(:user, name: "Anna")

      get :index, params: { assignee_filter: anna.id }

      assert_equal anna.id.to_s, @request.session[:assignee_filter]
    end

    should "filter publications by assignee parameter in preference to the one in the session" do
      anna = FactoryBot.create(:user, name: "Anna")
      bob = FactoryBot.create(:user, name: "Bob")
      @request.session[:assignee_filter] = bob.id

      get :index, params: { assignee_filter: anna.id }

      assert_response :ok
      assert_select "#assignee_filter > option[value='#{anna.id}'][selected]"
    end

    should "filter publications by content type" do
      FactoryBot.create(:guide_edition, assigned_to: @user)
      FactoryBot.create(:completed_transaction_edition, assigned_to: @user)

      get :index, params: { content_type_filter: "guide" }

      assert_response :ok
      assert_select "p.publications-table__heading", "1 document(s)"
      assert_select "dd.govuk-summary-list__value", "Guide"
    end

    should "filter publications by title text" do
      FactoryBot.create(:guide_edition, title: "How to train your dragon", assigned_to: @user)
      FactoryBot.create(:guide_edition, title: "What to do in the event of a zombie apocalypse", assigned_to: @user)

      get :index, params: { search_text: "zombie" }

      assert_response :ok
      assert_select "p.publications-table__heading", "1 document(s)"
      assert_select "p.title", /What to do in the event of a zombie apocalypse/
    end

    should "ignore unrecognised filter states" do
      FilteredEditionsPresenter
        .expects(:new)
        .with(anything, has_entry(:states_filter, %w[draft]))
        .returns(stub(
                   editions: Kaminari.paginate_array([]).page(1),
                   available_users: [],
                   search_text: "",
                   assignees: [],
                   content_types: [],
                   edition_states: [],
                 ))

      get :index, params: { search_text: "", states_filter: %w[draft not_a_real_state] }
    end

    should "show the first page of publications when no page is specified" do
      FactoryBot.create_list(
        :guide_edition, FilteredEditionsPresenter::ITEMS_PER_PAGE + 1, assigned_to: @user
      )

      get :index

      assert_response :ok
      assert_select "p.publications-table__heading", "#{FilteredEditionsPresenter::ITEMS_PER_PAGE + 1} document(s)"
      assert_select ".govuk-table__row .title", FilteredEditionsPresenter::ITEMS_PER_PAGE
    end

    should "show the specified page of publications" do
      FactoryBot.create_list(
        :guide_edition, FilteredEditionsPresenter::ITEMS_PER_PAGE + 1, assigned_to: @user
      )

      get :index, params: { page: 2 }

      assert_response :ok
      assert_select "p.publications-table__heading", "#{FilteredEditionsPresenter::ITEMS_PER_PAGE + 1} document(s)"
      assert_select ".govuk-table__row .title", 1
    end
  end
end
