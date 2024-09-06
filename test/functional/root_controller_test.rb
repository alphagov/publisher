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

    should "default the state filter checkboxes when no filters are specified" do
      get :index

      # These filters should be 'checked'
      assert_select "input.govuk-checkboxes__input[value='draft'][checked]"
      assert_select "input.govuk-checkboxes__input[value='amends_needed'][checked]"
      assert_select "input.govuk-checkboxes__input[value='in_review'][checked]"
      assert_select "input.govuk-checkboxes__input[value='fact_check'][checked]"
      assert_select "input.govuk-checkboxes__input[value='fact_check_received'][checked]"
      assert_select "input.govuk-checkboxes__input[value='ready'][checked]"

      # These filters should NOT be 'checked'
      assert_select "input.govuk-checkboxes__input[value='scheduled_for_publishing']"
      assert_select "input.govuk-checkboxes__input[value='scheduled_for_publishing'][checked]", false
      assert_select "input.govuk-checkboxes__input[value='published']"
      assert_select "input.govuk-checkboxes__input[value='published'][checked]", false
      assert_select "input.govuk-checkboxes__input[value='archived']"
      assert_select "input.govuk-checkboxes__input[value='archived'][checked]", false
    end

    should "default the applied state filters when no filters are specified" do
      FactoryBot.create(:edition, state: "draft")
      FactoryBot.create(:edition, state: "amends_needed")
      FactoryBot.create(:edition, state: "in_review", review_requested_at: 1.hour.ago)
      fact_check_edition = FactoryBot.create(:edition, state: "fact_check", title: "Check yo fax")
      fact_check_edition.new_action(FactoryBot.create(:user), "send_fact_check")
      FactoryBot.create(:edition, state: "fact_check_received")
      FactoryBot.create(:edition, state: "ready")
      FactoryBot.create(:edition, state: "scheduled_for_publishing", publish_at: Time.zone.now + 1.hour)
      FactoryBot.create(:edition, state: "published")
      FactoryBot.create(:edition, state: "archived")

      get :index

      assert_select "p.publications-table__heading", "6 document(s)"
      assert_select "span.govuk-tag--draft", "Draft"
      assert_select "span.govuk-tag--amends_needed", "Amends needed"
      assert_select "span.govuk-tag--in_review", "In review"
      assert_select "span.govuk-tag--fact_check", "Fact check"
      assert_select "span.govuk-tag--fact_check_received", "Fact check received"
      assert_select "span.govuk-tag--ready", "Ready"
    end

    should "filter publications by state" do
      FactoryBot.create(:guide_edition, state: "draft")
      FactoryBot.create(:guide_edition, state: "published")

      get :index, params: { states_filter: %w[draft] }

      assert_response :ok
      assert_select "p.publications-table__heading", "1 document(s)"
    end

    should "filter publications by assignee" do
      anna = FactoryBot.create(:user, name: "Anna")
      FactoryBot.create(:guide_edition, assigned_to: anna)
      FactoryBot.create(:guide_edition)

      get :index, params: { assignee_filter: anna.id }

      assert_response :ok
      assert_select "p.publications-table__heading", "1 document(s)"
    end

    should "filter publications by content type" do
      FactoryBot.create(:guide_edition)
      FactoryBot.create(:completed_transaction_edition)

      get :index, params: { content_type_filter: "guide" }

      assert_response :ok
      assert_select "p.publications-table__heading", "1 document(s)"
    end

    should "filter publications by title text" do
      FactoryBot.create(:guide_edition, title: "How to train your dragon")
      FactoryBot.create(:guide_edition, title: "What to do in the event of a zombie apocalypse")

      get :index, params: { title_filter: "zombie" }

      assert_response :ok
      assert_select "p.publications-table__heading", "1 document(s)"
    end

    should "ignore unrecognised filter states" do
      FilteredEditionsPresenter
        .expects(:new)
        .with(has_entry(:states_filter, %w[draft]))
        .returns(stub(
                   editions: Kaminari.paginate_array([]).page(1),
                   available_users: [],
                   title: "",
                   assignees: [],
                   content_types: [],
                   edition_states: [],
                 ))

      get :index, params: { title_filter: "", states_filter: %w[draft not_a_real_state] }
    end

    should "show the first page of publications when no page is specified" do
      FactoryBot.create_list(:guide_edition, FilteredEditionsPresenter::ITEMS_PER_PAGE + 1)

      get :index

      assert_response :ok
      assert_select "p.publications-table__heading", "#{FilteredEditionsPresenter::ITEMS_PER_PAGE + 1} document(s)"
      assert_select ".govuk-table__row .title", FilteredEditionsPresenter::ITEMS_PER_PAGE
    end

    should "show the specified page of publications" do
      FactoryBot.create_list(:guide_edition, FilteredEditionsPresenter::ITEMS_PER_PAGE + 1)

      get :index, params: { page: 2 }

      assert_response :ok
      assert_select "p.publications-table__heading", "#{FilteredEditionsPresenter::ITEMS_PER_PAGE + 1} document(s)"
      assert_select ".govuk-table__row .title", 1
    end
  end
end
