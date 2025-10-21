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

      @edition = @user.create_edition(:guide, panopticon_id: FactoryBot.create(:artefact).id, overview: "My Overview", title: "My Title", slug: "my-title")
      request_review(@user, @edition)
      approve_review(@other_user, @edition)
    end

    should "resend the fact check email for an edition in fact check state" do
      stub_calendars_has_no_bank_holidays(in_division: "england-and-wales")

      send_fact_check(@user, @edition)
      stubbed_fact_check_mail = stub("mailer", deliver_now: true)
      EventNotifierService.expects(:request_fact_check).returns(stubbed_fact_check_mail)
      resend_fact_check_action = @edition.new_action(@user, "resend_fact_check")

      mail = EventNotifierService.resend_fact_check(resend_fact_check_action)
      assert_equal stubbed_fact_check_mail, mail
    end

    should "return a NoMail instance if the edition is not in fact check state" do
      EventNotifierService.expects(:request_fact_check).never
      resend_fact_check_action = @edition.new_action(@user, "resend_fact_check")

      mail = EventNotifierService.resend_fact_check(resend_fact_check_action)
      assert mail.is_a? EventMailer::NoMail
    end

    should "return a NoMail instance if the supplied action is not a resend fact check one" do
      EventNotifierService.expects(:request_fact_check).never

      mail = EventNotifierService.resend_fact_check(@edition.latest_status_action)
      assert mail.is_a? EventMailer::NoMail
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
