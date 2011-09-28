require 'test_helper'

class Admin::TransactionsControllerTest < ActionController::TestCase

  setup do
    stub_request(:delete, "http://panopticon.dev.gov.uk/slugs/test").to_return(:status => 200)
    login_as_stub_user
    without_panopticon_validation do
      @transaction = Transaction.create(:name => "test", :slug=>"test")
    end
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
    @transaction.publish(@transaction.editions.first, "test note")
    assert !@transaction.can_destroy?
    @transaction.save!
    assert_difference('Transaction.count', 0) do
      delete :destroy, :id => @transaction.id
    end
  end

end
