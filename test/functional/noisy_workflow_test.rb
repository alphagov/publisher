require 'test_helper'

class NoisyWorkflowTest < ActionMailer::TestCase
  tests NoisyWorkflow

  def template_guide
    FactoryGirl.create(:guide_edition)
  end

  test "fact checking emails should set appropriate reply-to address" do
    guide = template_guide
    email = NoisyWorkflow.request_fact_check guide, {:email_addresses => 'jys@ketlai.co.uk', :customised_message => "Blah"}
    assert_equal ["factcheck+test-#{guide.id}@alphagov.co.uk"], email.reply_to
  end

  test "fact checking emails should go from appropriate email addresses" do
    guide = template_guide
    email = NoisyWorkflow.request_fact_check guide, {:email_addresses => 'jys@ketlai.co.uk', :customised_message => "Blah"}
    assert_equal ["factcheck+test-#{guide.id}@alphagov.co.uk"], email.from
  end

  test "news of publications should go to the whole team + franchise editors" do
    guide = template_guide
    requester = User.new(:name => 'Testing Person')
    action = guide.actions.create(:request_type => Action::PUBLISH, :requester => requester)
    email = NoisyWorkflow.make_noise(action)
    assert_equal email.to, ['govuk-team@digital.cabinet-office.gov.uk', 'freds@alphagov.co.uk']
  end

  test "review request emails should go to the editors, franchise editors, and the SEO team" do
    guide = template_guide
    requester = User.new(:name => 'Testing Person')
    action = guide.actions.create(:request_type => Action::REQUEST_REVIEW, :requester => requester)
    email = NoisyWorkflow.make_noise(action)
    assert_equal email.to, ['govuk-content-designers@digital.cabinet-office.gov.uk', 'seo@alphagov.co.uk', 'freds@alphagov.co.uk']
  end

  test "other workflow emails should go to editors and franchise editors" do
    guide = template_guide
    requester = User.new(:name => 'Testing Person')
    action = guide.actions.create(:request_type => Action::APPROVE_REVIEW, :requester => requester)
    email = NoisyWorkflow.make_noise(action)
    assert_equal email.to, ['govuk-content-designers@digital.cabinet-office.gov.uk', 'freds@alphagov.co.uk']
  end
end
