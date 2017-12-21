require 'test_helper'

class NoisyWorkflowTest < ActionMailer::TestCase
  tests NoisyWorkflow

  def fact_check_email
    guide = FactoryGirl.create(:guide_edition)
    action = guide.actions.create!(email_addresses: 'jys@ketlai.co.uk', customised_message: "Blah")
    email = NoisyWorkflow.request_fact_check(action)
    [guide, email]
  end

  def action_email(action)
    guide = FactoryGirl.create(:guide_edition, title: 'Test Guide 2')
    requester = User.new(name: 'Testing Person')
    action = guide.actions.create(request_type: action, requester: requester)
    NoisyWorkflow.make_noise(action)
  end

  def publisher_and_guide
    user = User.create(uid: "123", name: "Ben")
    other_user = User.create(uid: "321", name: "James")

    guide = user.create_edition(:guide, panopticon_id: FactoryGirl.create(:artefact).id, overview: 'My Overview', title: 'My Title', slug: 'my-title')
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
    stub_mailer = stub('mailer', deliver_now: true)
    NoisyWorkflow.expects(:request_fact_check).returns(stub_mailer)
    user = User.create(name: "Ben")
    artefact = FactoryGirl.create(:artefact)
    guide = user.create_edition(:guide, title: 'My Title', slug: 'my-title', panopticon_id: artefact.id)
    edition = guide
    edition.state = 'ready'
    assert edition.can_send_fact_check?
    send_fact_check(user, edition)
  end

  test "a guide should not send an email if creating a new edition fails" do
    user, guide = publisher_and_guide
    edition = guide.published_edition
    NoisyWorkflow.expects(:make_noise).never
    edition.expects(:build_clone).returns(false)
    assert ! user.new_version(edition)
  end

  test "should send an email on fact check received" do
    user = User.create(name: "Ben")
    guide = user.create_edition(:guide,
      panopticon_id: FactoryGirl.create(:artefact).id,
      overview: 'My Overview',
      title: 'My Title', slug: 'my-title-b')

    NoisyWorkflow.expects(:make_noise).returns(mock("noise maker", deliver_now: nil))
    receive_fact_check(user, guide)
  end

  test "fact checking emails should set appropriate reply-to address" do
    guide, email = fact_check_email
    assert_equal ["factcheck+dev-#{guide.id}@alphagov.co.uk"], email.reply_to
  end

  test "fact checking emails should go from appropriate email addresses" do
    guide, email = fact_check_email
    assert_equal ["factcheck+dev-#{guide.id}@alphagov.co.uk"], email.from
  end

  context '.resend_fact_check' do
    setup do
      @user = User.create(uid: "123", name: "Ben")
      @other_user = User.create(uid: "321", name: "James")

      @edition = @user.create_edition(:guide, panopticon_id: FactoryGirl.create(:artefact).id, overview: 'My Overview', title: 'My Title', slug: 'my-title')
      request_review(@user, @edition)
      approve_review(@other_user, @edition)
    end

    should 'resend the fact check email for an edition in fact check state' do
      send_fact_check(@user, @edition)
      stubbed_fact_check_mail = stub('mailer', deliver_now: true)
      NoisyWorkflow.expects(:request_fact_check).returns(stubbed_fact_check_mail)
      resend_fact_check_action = @edition.new_action(@user, 'resend_fact_check')

      mail = NoisyWorkflow.resend_fact_check(resend_fact_check_action)
      assert_equal stubbed_fact_check_mail, mail
    end

    should 'return a NoMail instance if the edition is not in fact check state' do
      NoisyWorkflow.expects(:request_fact_check).never
      resend_fact_check_action = @edition.new_action(@user, 'resend_fact_check')

      mail = NoisyWorkflow.resend_fact_check(resend_fact_check_action)
      assert mail.is_a? NoisyWorkflow::NoMail
    end

    should 'return a NoMail instance if the supplied action is not a resend fact check one' do
      NoisyWorkflow.expects(:request_fact_check).never

      mail = NoisyWorkflow.resend_fact_check(@edition.latest_status_action)
      assert mail.is_a? NoisyWorkflow::NoMail
    end
  end

  context "make_noise" do
    context "Setting the subject" do
      should "set a subject containing the description" do
        email = action_email(Action::APPROVE_REVIEW)
        assert_equal email.subject, "[PUBLISHER] Okayed for publication: \"Test Guide 2\" (Guide) by Testing Person"
      end
    end

    context "Setting the recipients" do
      should "send to 'publisher-alerts-citizen'" do
        email = action_email(Action::PUBLISH)
        assert email.to.include?('publisher-alerts-citizen@digital.cabinet-office.gov.uk')
        email = action_email(Action::REQUEST_REVIEW)
        assert email.to.include?('publisher-alerts-citizen@digital.cabinet-office.gov.uk')
      end
    end
  end
end
