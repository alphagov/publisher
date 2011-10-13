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
      assert ! user.request_fact_check(trans.editions.last, {comment: "Hello"})
    end
  end
  
  test "user can't okay a publication they've sent for review" do
    user = User.create(:name => "bob")

    without_panopticon_validation do
      trans = user.create_publication(:transaction, :name => "test", :slug => "test")
      user.request_review(trans.editions.last, {comment: "Hello"})
      assert ! user.okay(trans.editions.last, {comment: "Hello"})
    end
  end
  
  test "user can't send back a publication they've sent for review" do
    user = User.create(:name => "bob")

    without_panopticon_validation do
      trans = user.create_publication(:transaction, :name => "test", :slug => "test")
      user.request_review(trans.editions.last, {comment: "Hello"})
      assert ! user.review(trans.editions.last, {comment: "Hello"})
    end
  end
end
