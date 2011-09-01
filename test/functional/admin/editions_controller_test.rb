require 'test_helper'

class Admin::EditionsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
    without_panopticon_validation do
      @guide = Guide.create(:name => "test", :slug=>"test")
    end
  end
  
  test "an appropriate error message is shown if new edition failed" do
    stub_user = stub(:user)
    stub_user.stubs(:new_version).with(@guide.editions.first).returns(false)
    @controller.stubs(:current_user).returns(stub_user)
    
    post :create, :guide_id => @guide.id
    assert_response 302
    assert_equal "Failed to create new edition", flash[:alert]
  end
end
