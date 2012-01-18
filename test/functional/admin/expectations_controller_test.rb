require 'test_helper'

class Admin::ExpectationsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
  end

  test "creating an expectation works" do
    post :create, :expectation => {:text => 'It will cost money', :css_class => 'it-will-cost-money'}
    assert_response 302
    assert_equal "Expectation set", flash[:notice]
  end
end
