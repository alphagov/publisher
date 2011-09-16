require 'test_helper'


class Admin::ProgrammesControllerTest < ActionController::TestCase

  setup do
    stub_request(:delete, "http://panopticon.dev.gov.uk/slugs/test").to_return(:status => 200)
    login_as_stub_user
    without_panopticon_validation do
      @programme = Programme.create(:name => "test", :slug=>"test")
    end
  end

  test "programmes index redirects to root" do
    get :index
    assert_response :redirect
    assert_redirected_to(:controller => "root", "action" => "index")
  end

  test "we can view a programme" do
    get :show, :id => @programme.id
    assert_response :success
    assert_not_nil assigns(:programme)
  end

  test "destroy programme" do
    assert @programme.can_destroy?
    assert_difference('Programme.count', -1) do
      delete :destroy, :id => @programme.id
    end
    assert_redirected_to(:controller => "root", "action" => "index")
  end

  test "can't destroy published programme" do
    @programme.publish(@programme.editions.first, "test note")
    assert !@programme.can_destroy?
    @programme.save!
    assert_difference('Programme.count', 0) do
      delete :destroy, :id => @programme.id
    end
  end

end
