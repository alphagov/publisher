require 'test_helper'

class Admin::PublicationsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
  end
  
  test "when saving publication fails we show a page" do
    panopticon_has_metadata(
        "id" => 2357,
        "slug" => "foo-bar",
        "kind" => "local_transaction",
        "name" => "Foo bar"
    )
    get :show, :id => 2357
    assert_response :success
  end
end
