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

  context "#create" do
    setup do
      @popular_links = FactoryBot.create(:popular_links, state: "published")
    end

    should "render show template" do
      post :create, params: { id: @popular_links.id }

      assert_response :ok
      assert_template "homepage/popular_links/show"
    end

    should "create a new draft popular links" do
      assert_equal 1, PopularLinksEdition.count
      assert_equal "published", PopularLinksEdition.last.state

      post :create, params: { id: @popular_links.id }

      assert_equal 2, PopularLinksEdition.count
      assert_equal "draft", PopularLinksEdition.last.state
    end
  end
end
