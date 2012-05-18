# require 'test_helper'
#
# class Admin::TransactionsControllerTest < ActionController::TestCase
#
#   setup do
#     stub_request(:delete, "#{Plek.current.find("arbiter")}/slugs/test").to_return(:status => 200)
#     panopticon_has_metadata(
#       "id" => "test",
#       "name" => "FOOOO"
#     )
#     login_as_stub_user
#     @transaction = TransactionEdition.create!(title: "test", slug: "test", panopticon_id: '123')
#   end
#
#   test "transactions index redirects to root" do
#     get :index
#     assert_response :redirect
#     assert_redirected_to(:controller => "root", "action" => "index")
#   end
#
#   test "we can view a transaction" do
#     get :show, :id => @transaction.id
#     assert_response :success
#     assert_not_nil assigns(:transaction)
#   end
#
#   test "destroy transaction" do
#     assert @transaction.can_destroy?
#     assert_difference('TransactionEdition.count', -1) do
#       delete :destroy, :id => @transaction.id
#     end
#     assert_redirected_to(:controller => "root", "action" => "index")
#   end
#
#   test "can't destroy published transaction" do
#     @transaction.state = 'ready'
#     @transaction.publish
#     assert !@transaction.can_destroy?
#     @transaction.save!
#     assert_difference('TransactionEdition.count', 0) do
#       delete :destroy, :id => @transaction.id
#     end
#   end
# end
