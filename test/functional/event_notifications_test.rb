require "test_helper"

class EventNotificationsTest < ActiveSupport::TestCase
  def fact_check_email
    guide = FactoryBot.create(:guide_edition)
    action = guide.actions.create!(email_addresses: "jys@ketlai.co.uk", customised_message: "Blah")
    email = EventNotifierService.request_fact_check(action)
    [guide, email]
  end

  def action_email(action)
    guide = FactoryBot.create(:guide_edition, title: "Test Guide 2")
    requester = User.new(name: "Testing Person")
    requester.save!
    action = guide.actions.create!(request_type: action, requester:)
    EventNotifierService.any_action(action)
  end

  context ".resend_fact_check" do
    setup do
      @user = FactoryBot.create(:user, :govuk_editor, uid: "123", name: "Ben")
      @other_user = FactoryBot.create(:user, :govuk_editor, uid: "321", name: "James")

      @edition = FactoryBot.create(:edition, :fact_check)
    end

    context "fact_check_manager_api is not enabled" do
      setup do
        @test_strategy.switch!(:fact_check_manager_api, false)
      end

      should "resend the fact check email via 'request_fact_check' for an edition in 'fact_check' state" do
        stubbed_fact_check_mail = stub("mailer", deliver_now: true)
        EventNotifierService.expects(:request_fact_check).returns(stubbed_fact_check_mail)

        resend_fact_check_action = @edition.new_action(@user, "resend_fact_check")
        mail = EventNotifierService.resend_fact_check(resend_fact_check_action)

        assert_equal stubbed_fact_check_mail, mail
      end
    end

    context "fact_check_manager_api is enabled" do
      setup do
        @test_strategy.switch!(:fact_check_manager_api, true)
      end

      should "not attempt to resend the fact check email via 'request_fact_check' for an edition in 'fact_check' state" do
        EventNotifierService.expects(:request_fact_check).never

        resend_fact_check_action = @edition.new_action(@user, "resend_fact_check")
        mail = EventNotifierService.resend_fact_check(resend_fact_check_action)

        assert_nil mail
      end
    end

    should "Logs the error if the edition is not in fact check state" do
      EventNotifierService.expects(:request_fact_check).never
      edition = FactoryBot.create(:edition, :in_review)
      resend_fact_check_action = edition.new_action(@user, "resend_fact_check")
      Rails.logger.expects(:info).with("Asked to resend fact check for #{edition.content_id}, but its most recent status action is not a fact check, it's a #{edition.latest_status_action.request_type}")

      EventNotifierService.resend_fact_check(resend_fact_check_action)
    end

    should "logs the error if the supplied action is not a resend fact check one" do
      EventNotifierService.expects(:request_fact_check).never
      Rails.logger.expects(:info).with("Asked to resend fact check for #{@edition.content_id}, but its most recent status action is not a fact check, it's a #{@edition.latest_status_action.request_type}")

      EventNotifierService.resend_fact_check(@edition.latest_status_action)
    end
  end

  context "any_action" do
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
