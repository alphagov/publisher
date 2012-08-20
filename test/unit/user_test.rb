require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "it doesn't try to send a fact check email if no addresses were given" do
    user = User.create(:name => "bob")
    NoisyWorkflow.expects(:request_fact_check).never
    trans = user.create_edition(:transaction, title: "test answer", slug: "test", panopticon_id: FactoryGirl.create(:artefact).id)
    assert ! user.send_fact_check(trans, {comment: "Hello"})
  end

  test "when an user publishes a guide, a status message is sent on the message bus" do
    user = User.create(:name => "bob")
    second_user = User.create(:name => "dave")

    trans = user.create_edition(:transaction, title: "test answer", slug: "test", panopticon_id: FactoryGirl.create(:artefact).id)
    user.start_work(trans)
    user.request_review(trans, {comment: "Hello"})
    second_user.approve_review(trans, {comment: "Hello"})

    stub_register_published_content
    user.publish trans, {comment: "Published because I did"}
  end
end
