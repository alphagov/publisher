require "test_helper"

class HomepageControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
  end

  context "#show" do
    setup do
      @popular_links = FactoryBot.create(:popular_links)
    end

    should "render show template" do
      get :show

      assert_response :ok
      assert_template "homepage/popular_links/show"
    end
  end
end