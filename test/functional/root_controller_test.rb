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
  end
end
