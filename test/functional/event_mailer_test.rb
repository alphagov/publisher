require "test_helper"

class EventMailerTest < ActionMailer::TestCase
  tests EventMailer

  setup do
    stub_calendars_has_no_bank_holidays(in_division: "england-and-wales")
  end

  def fact_check_email
    guide = FactoryBot.create(:guide_edition)
    action = guide.actions.create!(email_addresses: "jys@ketlai.co.uk", customised_message: "Blah")
    email = EventMailer.request_fact_check(action, action.email_addresses)
    [guide, email]
  end

  def action_email(action_name)
    guide = FactoryBot.create(:guide_edition, title: "Test Guide 2")
    requester = User.new(name: "Testing Person")
    requester.save!
    action = guide.actions.create!(request_type: action_name, requester:)
    EventMailer.any_action(action, ["fake@not-a-real-email-address"])
  end

  def publisher_and_guide
    user = FactoryBot.create(:user, :govuk_editor, uid: "123", name: "Ben")
    other_user = FactoryBot.create(:user, :govuk_editor, uid: "321", name: "James")

    guide = user.create_edition(:guide, panopticon_id: FactoryBot.create(:artefact).id, overview: "My Overview", title: "My Title", slug: "my-title")
    edition = guide
    request_review(user, edition)
    approve_review(other_user, edition)
    send_fact_check(user, edition)
    receive_fact_check(user, edition)
    approve_fact_check(other_user, edition)
    stub_register_published_content
    publish(user, edition)
    [user, guide]
  end

  test "user should be able to have an email sent for fact checking" do
    stub_mailer = stub("mailer", deliver_now: true)
    EventMailer.expects(:request_fact_check).returns(stub_mailer)
    user = FactoryBot.create(:user, :govuk_editor, name: "Ben")
    artefact = FactoryBot.create(:artefact)
    guide = user.create_edition(:guide, title: "My Title", slug: "my-title", panopticon_id: artefact.id)
    edition = guide
    edition.state = "ready"
    assert edition.can_send_fact_check?
    send_fact_check(user, edition)
  end

  test "a guide should not send an email if creating a new edition fails" do
    user, guide = publisher_and_guide
    edition = guide.published_edition
    EventMailer.expects(:any_action).never
    edition.expects(:build_clone).returns(false)
    assert_not user.new_version(edition)
  end

  test "should send an email on fact check received" do
    user = FactoryBot.create(:user, :govuk_editor, name: "Ben")
    guide = user.create_edition(
      :guide,
      panopticon_id: FactoryBot.create(:artefact).id,
      overview: "My Overview",
      title: "My Title",
      slug: "my-title-b",
    )

    EventMailer.expects(:any_action).returns(mock("event email", deliver_now: nil))
    EventMailer.expects(:any_action).returns(mock("event email", deliver_now: nil))
    receive_fact_check(user, guide)
  end

  context ".skip_review" do
    should "should send an email on skipping review" do
      user = FactoryBot.create(:user, name: "Ben", permissions: %w[govuk_editor skip_review])
      guide = user.create_edition(:guide, panopticon_id: FactoryBot.create(:artefact).id, overview: "My Overview", title: "My Title", slug: "my-title")
      request_review(user, guide)
      EventMailer.expects(:skip_review).returns(mock("event email", deliver_now: nil))
      skip_review(user, guide)
    end
  end

  context "any_action" do
    context "Setting the subject" do
      should "set a subject containing the description" do
        email = action_email(Action::APPROVE_REVIEW)
        assert_equal email.subject, "[PUBLISHER] Okayed for publication: \"Test Guide 2\" (Guide) by Testing Person"
      end
    end
  end
end
