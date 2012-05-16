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

  def publisher_and_guide
    user = User.create(:name => "Ben")
    other_user = User.create(:name => "James")

    guide = user.create_whole_edition(:guide, :panopticon_id => 1234574, :overview => 'My Overview', :title => 'My Title', :slug => 'my-title', :alternative_title => 'My Other Title')
    edition = guide
    user.start_work(edition)
    user.request_review(edition,{:comment => "Review this guide please."})
    other_user.approve_review(edition, {:comment => "I've reviewed it"})
    user.send_fact_check(edition,{:comment => "Review this guide please.", :email_addresses => 'test@test.com'})
    user.receive_fact_check(edition, {:comment => "No changes needed, this is all correct"})
    other_user.approve_fact_check(edition, {:comment => "Looks good to me"})
    user.publish(edition, {:comment => "PUBLISHED!"})
    return user, guide
  end

  test "user should be able to have an email sent for fact checking" do
    stub_mailer = stub('mailer', :deliver => true)
    NoisyWorkflow.expects(:request_fact_check).returns(stub_mailer)
    user = User.create(:name => "Ben")

    guide = user.create_whole_edition(:guide, title: 'My Title', slug: 'my-title', panopticon_id: '12345')
    edition = guide
    edition.state = 'ready'
    assert edition.can_send_fact_check?
    user.send_fact_check(edition, {:email_addresses => "js@alphagov.co.uk, james.stewart@digital.cabinet-office.gov.uk", :customised_message => "Our message"})
  end

  test "a guide should not send an email if creating a new edition fails" do
    user, guide = publisher_and_guide
    edition = guide.published_edition
    NoisyWorkflow.expects(:make_noise).never
    edition.expects(:build_clone).returns(false)
    assert ! user.new_version(edition)
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
      should "send to 'publisher-alerts-business' for a business edition" do
        email = business_action_email(Action::PUBLISH)
        assert_equal email.to.sort, ['publisher-alerts-business@digital.cabinet-office.gov.uk'].sort
        email = business_action_email(Action::APPROVE_REVIEW)
        assert_equal email.to, ['publisher-alerts-business@digital.cabinet-office.gov.uk']
      end

      should "send to 'publisher-alerts-citizen' and 'freds' for a non-business edition" do
        email = action_email(Action::PUBLISH)
        assert_equal email.to.sort, ['publisher-alerts-citizen@digital.cabinet-office.gov.uk', 'freds@alphagov.co.uk'].sort
        email = action_email(Action::REQUEST_REVIEW)
        assert_equal email.to.sort, ['publisher-alerts-citizen@digital.cabinet-office.gov.uk', 'freds@alphagov.co.uk'].sort
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
