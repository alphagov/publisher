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

    should "filter publications by state" do
      FactoryBot.create(:guide_edition, state: "draft")
      FactoryBot.create(:guide_edition, state: "published")

      get :index, params: { states_filter: %w[draft] }

      assert_response :ok
      assert_select "p.publications-table__heading", "1 document(s)"
    end

    should "filter publications by assignee" do
      anna = FactoryBot.create(:user, name: "Anna")
      FactoryBot.create(:guide_edition)

      get :index, params: { assignee_filter: [anna.id] }

      assert_response :ok
      assert_select "p.publications-table__heading", "1 document(s)"
    end

    should "filter publications by format" do
      FactoryBot.create(:guide_edition)
      FactoryBot.create(:completed_transaction_edition)

      get :index, params: { format_filter: "guide" }

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
        .returns(stub(editions: [], available_users: []))

      get :index, params: { states_filter: %w[draft not_a_real_state] }
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
