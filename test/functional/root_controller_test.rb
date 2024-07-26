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
      assert_select "h2", "1 document(s)"
    end

    should "filter publications by assignee" do
      anna = FactoryBot.create(:user, name: "Anna")
      FactoryBot.create(:guide_edition)

      get :index, params: { assignee_filter: [anna.id] }

      assert_response :ok
      assert_select "h2", "1 document(s)"
    end

    should "filter publications by format" do
      FactoryBot.create(:guide_edition)
      FactoryBot.create(:completed_transaction_edition)

      get :index, params: { format_filter: "guide" }

      assert_response :ok
      assert_select "h2", "1 document(s)"
    end

    should "filter publications by title text" do
      FactoryBot.create(:guide_edition, title: "How to train your dragon")
      FactoryBot.create(:guide_edition, title: "What to do in the event of a zombie apocalypse")

      get :index, params: { title_filter: "zombie" }

      assert_response :ok
      assert_select "h2", "1 document(s)"
    end

    should "ignore unrecognised filter states" do
      FilteredEditionsPresenter.expects(:new).with(%w[draft], anything, anything, anything)
                               .returns(stub(editions: [], available_users: []))

      get :index, params: { states_filter: %w[draft not_a_real_state] }
    end
  end
end
