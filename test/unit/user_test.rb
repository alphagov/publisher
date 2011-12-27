require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "creating a transaction with the initial details creates a valid transaction" do
    user = User.create(:name => "bob")
    without_panopticon_validation do
      trans = user.create_whole_edition(:transaction, title: "test", slug: "test", panopticon_id: 1234)
      assert trans.valid?
    end
  end

  test "it doesn't try to send a fact check email if no addresses were given" do
    user = User.create(:name => "bob")
    NoisyWorkflow.expects(:request_fact_check).never
    without_panopticon_validation do
      trans = user.create_whole_edition(:transaction, title: "test answer", slug: "test", panopticon_id: 123)
      assert ! user.send_fact_check(trans, {comment: "Hello"})
    end
  end

  test "user can't okay a publication they've sent for review" do
    user = User.create(:name => "bob")

    without_panopticon_validation do
      trans = user.create_whole_edition(:transaction, title: "test answer", slug: "test", panopticon_id: 123)
      user.request_review(trans, {comment: "Hello"})
      assert ! user.approve_review(trans, {comment: "Hello"})
    end
  end

  test "when an user publishes a guide, a status message is sent on the message bus" do
    user = User.create(:name => "bob")
    second_user = User.create(:name => "dave")

    trans = user.create_whole_edition(:transaction, title: "test answer", slug: "test", panopticon_id: 123)
    user.start_work(trans)
    user.request_review(trans, {comment: "Hello"})
    second_user.approve_review(trans, {comment: "Hello"})

    Messenger.instance.expects(:published).with(trans).once
    user.publish trans, {comment: "Published because I did"}
  end

  test "Edition becomes assigned to user when user is assigned an edition" do
    boss_user = User.create(:name => "Mat")
    worker_user = User.create(:name => "Grunt")

    publication = boss_user.create_whole_edition(:answer, title: "test answer", slug: "test", panopticon_id: 123)
    boss_user.assign(publication, worker_user)
    publication.save
    publication.reload

    assert_equal(worker_user, publication.assigned_to)
  end

end
