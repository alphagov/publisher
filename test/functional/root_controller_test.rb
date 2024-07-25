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

    should "ignore unrecognised filter states" do
      FilteredEditionsPresenter.expects(:new).with(%w[draft], anything).returns(stub(editions: []))

      get :index, params: { states_filter: %w[draft not_a_real_state] }
    end
  end
end
