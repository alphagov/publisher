require 'test_helper'

class Admin::OverviewControllerTest < ActionController::TestCase

  setup do
    login_as_stub_user
  end

  test "we can view the overview" do
    get :index
    assert_response :success
    assert_not_nil assigns(:overviews)
  end
end
