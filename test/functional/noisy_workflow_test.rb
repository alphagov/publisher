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
    guide = FactoryGirl.create(:guide_edition, :title => 'Test Guide 2')
    requester = User.new(:name => 'Testing Person')
    action = guide.actions.create(:request_type => action, :requester => requester)
    NoisyWorkflow.make_noise(action)
  end

  def publisher_and_guide
    user = User.create(:name => "Ben")
    other_user = User.create(:name => "James")

    guide = user.create_edition(:guide, :panopticon_id => FactoryGirl.create(:artefact).id, :overview => 'My Overview', :title => 'My Title', :slug => 'my-title', :alternative_title => 'My Other Title')
    edition = guide
    user.request_review(edition,{:comment => "Review this guide please."})
    other_user.approve_review(edition, {:comment => "I've reviewed it"})
    user.send_fact_check(edition,{:comment => "Review this guide please.", :email_addresses => 'test@test.com'})
    user.receive_fact_check(edition, {:comment => "No changes needed, this is all correct"})
    other_user.approve_fact_check(edition, {:comment => "Looks good to me"})
    stub_register_published_content
    user.publish(edition, {:comment => "PUBLISHED!"})
    return user, guide
  end

  test "user should be able to have an email sent for fact checking" do
    stub_mailer = stub('mailer', :deliver => true)
    NoisyWorkflow.expects(:request_fact_check).returns(stub_mailer)
    user = User.create(:name => "Ben")
    artefact = FactoryGirl.create(:artefact)
    guide = user.create_edition(:guide, title: 'My Title', slug: 'my-title', panopticon_id: artefact.id)
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

  test "should send an email on fact check received" do
    user = User.create(:name => "Ben")
    guide = user.create_edition(:guide, 
      :panopticon_id => FactoryGirl.create(:artefact).id, 
      :overview => 'My Overview', 
      :title => 'My Title', :slug => 'my-title-b', :alternative_title => 'My Other Title')

    NoisyWorkflow.expects(:make_noise).returns(mock("noise maker", deliver: nil))
    user.receive_fact_check(guide, { comment: "Yo facts are wrong, dog." })
  end

  test "fact checking emails should set appropriate reply-to address" do
    guide, email = fact_check_email
    assert_equal ["factcheck+dev-#{guide.id}@alphagov.co.uk"], email.reply_to
  end

  test "fact checking emails should go from appropriate email addresses" do
    guide, email = fact_check_email
    assert_equal ["factcheck+dev-#{guide.id}@alphagov.co.uk"], email.from
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
