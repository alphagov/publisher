require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "creating a transaction with the initial details creates a valid transaction" do
    user = User.create(:name => "bob")
    without_panopticon_validation do
      trans = user.create_publication(:transaction, :name => "test", :slug => "test")
      assert trans.valid?
    end
  end
  
  test "it doesn't try to send a fact check email if no addresses were given" do
    user = User.create(:name => "bob")
    NoisyWorkflow.expects(:request_fact_check).never
    without_panopticon_validation do
      trans = user.create_publication(:transaction, :name => "test", :slug => "test")
      user.request_fact_check(trans.editions.last, {comment: "Hello"})
    end
  end
end
