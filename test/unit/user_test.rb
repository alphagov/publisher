require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "it doesn't try to send a fact check email if no addresses were given" do
    user = User.create(:name => "bob")
    NoisyWorkflow.expects(:request_fact_check).never
    trans = user.create_edition(:transaction, title: "test answer", slug: "test", panopticon_id: FactoryGirl.create(:artefact).id)
    refute send_fact_check(user, trans)
  end

  test "when an user publishes a guide, a status message is sent on the message bus" do
    user = User.create(:uid => '123', :name => "bob")
    second_user = User.create(:uid => '321', :name => "dave")

    trans = user.create_edition(:transaction, title: "test answer", slug: "test", panopticon_id: FactoryGirl.create(:artefact).id)
    request_review(user, trans)
    approve_review(second_user, trans)

    stub_register_published_content
    publish user, trans
  end

  test "use a custom collection for users" do
    assert_equal "publisher_users", User.collection_name
  end
end
