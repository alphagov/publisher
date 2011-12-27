require 'test_helper'

class NoisyWorkflowTest < ActionMailer::TestCase
  tests NoisyWorkflow

  def template_guide
    FactoryGirl.create(:guide_edition)
  end

  def fact_check_email
    guide = template_guide
    action = guide.actions.create!(:email_addresses => 'jys@ketlai.co.uk', :customised_message => "Blah")
    email = NoisyWorkflow.request_fact_check(action)
    return guide, email
  end

  def action_email(action)
    guide = template_guide
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
end
