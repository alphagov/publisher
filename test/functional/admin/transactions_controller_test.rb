require 'test_helper'

class Admin::TransactionsControllerTest < ActionController::TestCase

  setup do
    stub_request(:delete, "#{Plek.current.find("arbiter")}/slugs/test").to_return(:status => 200)
    stub_request(:get, "#{Plek.current.find("arbiter")}/artefacts/test.js").to_return(:status => 200, :body => '{"name":"FOOOO"}')
    login_as_stub_user
    without_metadata_denormalisation(Transaction) do
      @transaction = Transaction.create!(:name => "test", :slug=>"test")
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
    without_metadata_denormalisation(Transaction) do
      @transaction.editions.first.state = 'ready'
      @transaction.editions.first.publish
      assert !@transaction.can_destroy?
      @transaction.save!
      assert_difference('Transaction.count', 0) do
        delete :destroy, :id => @transaction.id
      end
    end
  end

end
