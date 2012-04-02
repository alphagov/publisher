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
    guide = FactoryGirl.create(:guide_edition)
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

  test "news of publications should go to the whole team + franchise editors" do
    email = action_email(Action::PUBLISH)
    assert_equal email.to, ['govuk-team@digital.cabinet-office.gov.uk', 'freds@alphagov.co.uk']
  end

  test "review request emails should go to the editors, franchise editors, and the SEO team" do
    email = action_email(Action::REQUEST_REVIEW)
    assert_equal email.to, ['govuk-content-designers@digital.cabinet-office.gov.uk', 'seo@alphagov.co.uk', 'freds@alphagov.co.uk']
  end

  test "other workflow emails should go to editors and franchise editors" do
    email = action_email(Action::APPROVE_REVIEW)
    assert_equal email.to, ['govuk-content-designers@digital.cabinet-office.gov.uk', 'freds@alphagov.co.uk']
  end

  test "publish business proposition email" do
    email = business_action_email(Action::PUBLISH)
    assert_equal email.to, ['govuk-team@digital.cabinet-office.gov.uk', 'publisher-alerts-business@digital.cabinet-office.gov.uk']
    assert_equal email.subject, "[PUBLISHER]-BUSINESS Published: \"Test Guide 1\" (Guide) by Testing Person"
  end

  test "review business proposition email" do
    email = business_action_email(Action::REQUEST_REVIEW)
    assert_equal email.to, ['publisher-alerts-business@digital.cabinet-office.gov.uk']
    assert_equal email.subject, "[PUBLISHER]-BUSINESS Review requested: \"Test Guide 1\" (Guide) by Testing Person"
  end

end
