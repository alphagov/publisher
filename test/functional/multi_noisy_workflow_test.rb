require "test_helper"

class MultiNoisyWorkflowTest < ActionMailer::TestCase
  tests MultiNoisyWorkflow

  def fact_check_email
    guide = FactoryBot.create(:guide_edition)
    action = guide.actions.create!(email_addresses: "jys@ketlai.co.uk", customised_message: "Blah")
    email = MultiNoisyWorkflow.request_fact_check(action)
    [guide, email]
  end

  def action_email(action)
    guide = FactoryBot.create(:guide_edition, title: "Test Guide 2")
    requester = User.new(name: "Testing Person")
    action = guide.actions.create(request_type: action, requester: requester)
    MultiNoisyWorkflow.make_noise(action)
  end

  context ".resend_fact_check" do
    setup do
      @user = User.create(uid: "123", name: "Ben")
      @other_user = User.create(uid: "321", name: "James")

      @edition = @user.create_edition(:guide, panopticon_id: FactoryBot.create(:artefact).id, overview: "My Overview", title: "My Title", slug: "my-title")
      request_review(@user, @edition)
      approve_review(@other_user, @edition)
    end

    should "resend the fact check email for an edition in fact check state" do
      send_fact_check(@user, @edition)
      stubbed_fact_check_mail = stub("mailer", deliver_now: true)
      MultiNoisyWorkflow.expects(:request_fact_check).returns(stubbed_fact_check_mail)
      resend_fact_check_action = @edition.new_action(@user, "resend_fact_check")

      mail = MultiNoisyWorkflow.resend_fact_check(resend_fact_check_action)
      assert_equal stubbed_fact_check_mail, mail
    end

    should "return a NoMail instance if the edition is not in fact check state" do
      MultiNoisyWorkflow.expects(:request_fact_check).never
      resend_fact_check_action = @edition.new_action(@user, "resend_fact_check")

      mail = MultiNoisyWorkflow.resend_fact_check(resend_fact_check_action)
      assert mail.is_a? NoisyWorkflow::NoMail
    end

    should "return a NoMail instance if the supplied action is not a resend fact check one" do
      MultiNoisyWorkflow.expects(:request_fact_check).never

      mail = MultiNoisyWorkflow.resend_fact_check(@edition.latest_status_action)
      assert mail.is_a? NoisyWorkflow::NoMail
    end
  end

  context "make_noise" do
    context "Setting the recipients" do
      should "send to 'publisher-alerts-citizen'" do
        email = action_email(Action::PUBLISH)
        assert email.map(&:to).flatten.include?("publisher-alerts-citizen@digital.cabinet-office.gov.uk")
        email = action_email(Action::REQUEST_REVIEW)
        assert email.map(&:to).flatten.include?("publisher-alerts-citizen@digital.cabinet-office.gov.uk")
      end
    end
  end
end
