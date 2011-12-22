# require 'test_helper'
# 
# class Admin::ProgrammesControllerTest < ActionController::TestCase
# 
#   setup do
#     panopticon_has_metadata(
#       "id" => "12345",
#       "name" => "Test",
#       "slug" => "test"
#     )
#     login_as_stub_user
#     @programme = ProgrammeEdition.create(title: "test", slug: "test", panopticon_id: 12345)
#   end
# 
#   test "programmes index redirects to root" do
#     get :index
#     assert_response :redirect
#     assert_redirected_to(:controller => "root", "action" => "index")
#   end
# 
#   test "requesting a publication that doesn't exist returns a 404" do
#     get :show, :id => '4e663834e2ba80480a0000e6'
#     assert_response 404
#   end
# 
#   test "we can view a programme" do
#     get :show, :id => @programme.id
#     assert_response :success
#     assert_not_nil assigns(:programme)
#   end
# 
#   test "destroy programme" do
#     assert @programme.can_destroy?
#     assert_difference('ProgrammeEdition.count', -1) do
#       delete :destroy, :id => @programme.id
#     end
#     assert_redirected_to(:controller => "root", "action" => "index")
#   end
# 
#   test "can't destroy published programme" do
#     @programme.state = 'ready'
#     @programme.save!
#     @programme.publish
#     @programme.save!
#     assert @programme.published?
#     assert !@programme.can_destroy?
#     
#     assert_difference('ProgrammeEdition.count', 0) do
#       delete :destroy, :id => @programme.id
#     end
#   end
# 
# end
