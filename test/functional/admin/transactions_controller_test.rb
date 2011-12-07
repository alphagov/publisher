require 'test_helper'

class Admin::TransactionsControllerTest < ActionController::TestCase

  setup do
    stub_request(:delete, "#{Plek.current.find("arbiter")}/slugs/test").to_return(:status => 200)
    panopticon_has_metadata(
      "id" => "test",
      "name" => "FOOOO"
    )
    login_as_stub_user
    @transaction = Transaction.create!(:name => "test", :slug=>"test")
  end

  test "transactions index redirects to root" do
    get :index
    assert_response :redirect
    assert_redirected_to(:controller => "root", "action" => "index")
  end

  test "we can view a transaction" do
    get :show, :id => @transaction.id
    assert_response :success
    assert_not_nil assigns(:transaction)
  end

  test "destroy transaction" do
    assert @transaction.can_destroy?
    assert_difference('Transaction.count', -1) do
      delete :destroy, :id => @transaction.id
    end
    assert_redirected_to(:controller => "root", "action" => "index")
  end

  test "can't destroy published transaction" do
    @transaction.editions.first.state = 'ready'
    @transaction.editions.first.publish
    assert !@transaction.can_destroy?
    @transaction.save!
    assert_difference('Transaction.count', 0) do
      delete :destroy, :id => @transaction.id
    end
  end
end
