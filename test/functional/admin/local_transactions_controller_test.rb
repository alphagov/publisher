require 'test_helper'

class Admin::LocalTransactionsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
    @guide = Guide.create(:name => "test", :slug=>"test")
    @user = User.create
    @controller.stubs(:current_user).returns(@user)
  end

  test "it renders the new template successfully if creation fails" do
    post :create, "local_transaction" => {"lgsl_code"=>"801", "panopticon_id"=>"827"}
    assert_equal '200', response.code
  end
end