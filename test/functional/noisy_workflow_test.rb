require 'test_helper'

class NoisyWorkflowTest < ActionMailer::TestCase
  tests NoisyWorkflow

  def fact_check_email
    guide = FactoryGirl.create(:guide_edition)
    action = guide.actions.create!(:email_addresses => 'jys@ketlai.co.uk', :customised_message => "Blah")
    email = NoisyWorkflow.request_fact_check(action)
    return guide, email
  end

  def action_email(action)
    guide = FactoryGirl.create(:guide_edition, :business_proposition => false, :title => 'Test Guide 2')
    requester = User.new(:name => 'Testing Person')
    action = guide.actions.create(:request_type => action, :requester => requester)
    NoisyWorkflow.make_noise(action)
  end

  def business_action_email(action)
    guide = FactoryGirl.create(:guide_edition, :business_proposition => true, :title => 'Test Guide 1')
    requester = User.new(:name => 'Testing Person')
    action = guide.actions.create(:request_type => action, :requester => requester)
    NoisyWorkflow.make_noise(action)
  end

  test "fact checking emails should set appropriate reply-to address" do
    guide, email = fact_check_email
    assert_equal ["factcheck+test-#{guide.id}@alphagov.co.uk"], email.reply_to
  end

  test "fact checking emails should go from appropriate email addresses" do
    guide, email = fact_check_email
    assert_equal ["factcheck+test-#{guide.id}@alphagov.co.uk"], email.from
  end

  context "make_noise" do
    context "Setting the subject" do

      should "set a subject containing the description and business prefix for business" do
        email = business_action_email(Action::PUBLISH)
        assert_equal email.subject, "[PUBLISHER]-BUSINESS Published: \"Test Guide 1\" (Guide) by Testing Person"
      end

      should "set a subject containing the description and non-business prefix for non-business" do
        email = action_email(Action::APPROVE_REVIEW)
        assert_equal email.subject, "[PUBLISHER] Okayed for publication: \"Test Guide 2\" (Guide) by Testing Person"
      end
    end

    context "Setting the recipients" do
      context "For a business edition" do
        should "send to 'biz' and 'team' for publish action" do
          email = business_action_email(Action::PUBLISH)
          assert_equal email.to.sort, ['govuk-team@digital.cabinet-office.gov.uk', 'publisher-alerts-business@digital.cabinet-office.gov.uk'].sort
        end

        should "send to 'biz' for all non-publish actions" do
          email = business_action_email(Action::REQUEST_REVIEW)
          assert_equal email.to, ['publisher-alerts-business@digital.cabinet-office.gov.uk']
          email = business_action_email(Action::APPROVE_REVIEW)
          assert_equal email.to, ['publisher-alerts-business@digital.cabinet-office.gov.uk']
        end
      end

      context "For a non-business edition" do
        should "send to 'freds' and 'team' for publish action" do
          email = action_email(Action::PUBLISH)
          assert_equal email.to.sort, ['govuk-team@digital.cabinet-office.gov.uk', 'freds@alphagov.co.uk'].sort
        end

        should "send to 'eds' and 'freds' for publish action" do
          email = action_email(Action::REQUEST_REVIEW)
          assert_equal email.to.sort, ['govuk-content-designers@digital.cabinet-office.gov.uk', 'freds@alphagov.co.uk'].sort
          email = action_email(Action::APPROVE_REVIEW)
          assert_equal email.to.sort, ['govuk-content-designers@digital.cabinet-office.gov.uk', 'freds@alphagov.co.uk'].sort
        end
      end

      should "send to 'devs' when in 'preview' environment" do
        plek_current = Plek.current
        plek_current.stubs(:environment).returns('preview')
        Plek.stubs(:current).returns( plek_current )
        email = business_action_email(Action::PUBLISH)
        assert_equal email.to, ['govuk-dev@digital.cabinet-office.gov.uk']
        email = action_email(Action::REQUEST_REVIEW)
        assert_equal email.to, ['govuk-dev@digital.cabinet-office.gov.uk']
      end
    end
  end
end
