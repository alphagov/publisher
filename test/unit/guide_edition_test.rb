require 'test_helper'

class GuideEditionTest < ActiveSupport::TestCase
  setup do
    panopticon_has_metadata("id" => '1234574', "name" => "Childcare", "slug" => "childcare")
  end
  
  def template_guide
    edition = FactoryGirl.create(:guide_edition, slug: "childcare", title: "One", panopticon_id: 1234574)
    edition.start_work
    edition.save
    edition
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

  test "order parts shouldn't fail if one part's order attribute is nil" do
    edition = template_guide
    edition.parts.build
    edition.parts.build(:order => 1)
    assert edition.order_parts
  end
  
  test 'a new guide has lined_up but isn\'t published' do
    g = FactoryGirl.create(:guide_edition)
    assert g.lined_up?
    assert !g.published?
  end

  test 'when work started a new guide has draft but isn\'t published' do
    g = FactoryGirl.create(:guide_edition)
    g.start_work
    assert g.draft?
    assert !g.published?
  end

  test "struct for search index" do
    guide = template_guide
    data = guide.search_index
    assert_equal ["title", "link", "section", "format", "description", "indexable_content", "additional_links"], data.keys
    assert_equal guide.title, data['title']
    assert_equal "guide", data['format']
  end

  test "indexable content contains parts for search index" do
    edition = template_guide
    edition.parts.build(:body => "ONE", :title => "ONE", :slug => "/one")
    edition.parts.build(:body => "TWO", :title => "TWO", :slug => "/two")
    data = edition.search_index
    assert_equal "ONE ONE TWO TWO", data['indexable_content']
  end

  test "index contains parts as additional links" do
    edition = template_guide
    edition.parts.build(:body => "ONE", :title => "ONE", :slug => "one")
    edition.parts.build(:body => "TWO", :title => "TWO", :slug => "two")
    data = edition.search_index
    assert_equal 2, data['additional_links'].count
  end

  test 'a guide without a video url should not have a video' do
    g = FactoryGirl.create(:guide_edition)
    assert !g.has_video?
  end

  test 'a guide with a video url should have a video' do
    g = FactoryGirl.create(:guide_edition)
    g.video_url = "http://www.youtube.com/watch?v=QH2-TGUlwu4"
    assert g.has_video?
  end

  test "a guide should be marked as having reviewables if requested for review" do
    guide = template_guide
    user = User.create(:name=>"Ben")
    assert !guide.in_review?
    user.request_review(guide, {:comment => "Review this guide please."})
    assert guide.in_review?
  end

  test "guide workflow" do
    user = User.create(:name => "Ben")
    other_user = User.create(:name => "James")

    guide = user.create_whole_edition(:guide, title: 'My Title', slug: 'my-title', panopticon_id: '12345')
    edition = guide
    user.start_work(edition)
    assert edition.can_request_review?
    user.request_review(edition,{:comment => "Review this guide please."})
    assert !edition.can_request_review?
    assert edition.can_request_amendments?
    other_user.request_amendments(edition, {:comment => "I've reviewed it"})
    assert !edition.can_request_amendments?
    user.request_review(edition,{:comment => "Review this guide please."})
    assert edition.can_approve_review?
    other_user.approve_review(edition, {:comment => "Looks good to me"})
    assert edition.can_publish?
  end

  test "check counting reviews" do
    user = User.create(:name => "Ben")
    other_user = User.create(:name => "James")

    guide = user.create_whole_edition(:guide, title: 'My Title', slug: 'my-title', panopticon_id: '12345')
    edition = guide

    assert_equal 0, guide.rejected_count

    user.start_work(edition)
    user.request_review(edition,{:comment => "Review this guide please."})
    other_user.request_amendments(edition, {:comment => "I've reviewed it"})

    assert_equal 1, guide.rejected_count

    user.request_review(edition,{:comment => "Review this guide please."})
    other_user.approve_review(edition, {:comment => "Looks good to me"})

    assert_equal 1, guide.rejected_count
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

  test "user should not be able to review a guide they requested review for" do
    user = User.create(:name => "Ben")

    guide = user.create_whole_edition(:guide, title: 'My Title', slug: 'my-title', panopticon_id: '12345')
    edition = guide
    user.start_work(edition)
    assert edition.can_request_review?
    user.request_review(edition,{:comment => "Review this guide please."})
    assert ! user.request_amendments(edition, {:comment => "Well Done, but work harder"})
  end

  test "user should not be able to okay a guide they requested review for" do
    user = User.create(:name => "Ben")

    guide = user.create_whole_edition(:guide, title: 'My Title', slug: 'my-title', panopticon_id: '12345')
    edition = guide
    user.start_work(edition)
    assert edition.can_request_review?
    user.request_review(edition,{:comment => "Review this guide please."})
    assert ! user.approve_review(edition, '')
  end

  test "you can only create a new edition from a published edition" do
    user = User.create(:name => "Ben")

    guide = user.create_whole_edition(:guide, title: 'My Title', slug: 'my-title', panopticon_id: '12345')
    edition = guide
    assert ! edition.published?
    assert ! user.new_version(edition)
  end

  test "a guide should not send an email if creating a new edition fails" do
    user, guide = publisher_and_guide
    edition = guide.published_edition
    NoisyWorkflow.expects(:make_noise).never
    edition.expects(:build_clone).returns(false)
    assert ! user.new_version(edition)
  end

  test "duplicating a guide should duplicate overview and alt title" do
    user, guide = publisher_and_guide
    edition = guide.published_edition

    assert ! edition.alternative_title.blank?
    assert ! edition.overview.blank?

    new_edition = user.new_version(edition)
    assert_equal edition.alternative_title, new_edition.alternative_title
    assert_equal edition.overview, new_edition.overview
  end
  
end