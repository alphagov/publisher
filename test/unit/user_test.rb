require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "it doesn't try to send a fact check email if no addresses were given" do
    stub_holidays_used_by_fact_check

    user = FactoryBot.create(:user, :govuk_editor, name: "bob")
    EventMailer.expects(:request_fact_check).never
    trans = user.create_edition(:transaction, title: "test answer", slug: "test", panopticon_id: FactoryBot.create(:artefact).id)
    assert_not send_fact_check(user, trans)
  end

  test "when an user publishes a guide, a status message is sent on the message bus" do
    user = FactoryBot.create(:user, :govuk_editor, uid: "123", name: "bob")
    second_user = FactoryBot.create(:user, :govuk_editor, uid: "321", name: "dave")

    trans = user.create_edition(:transaction, title: "test answer", slug: "test", panopticon_id: FactoryBot.create(:artefact).id)
    request_review(user, trans)
    approve_review(second_user, trans)

    stub_register_published_content
    publish user, trans
  end
end
