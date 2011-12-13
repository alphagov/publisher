require 'test_helper'

class GuideTest < ActiveSupport::TestCase

  setup do
    panopticon_has_metadata("id" => '1234574', "name" => "Childcare", "slug" => "childcare")
  end

  def template_guide
    g = Guide.new :slug=>"childcare", :name=>"Something", :panopticon_id => 1234574
    edition = g.editions.first
    edition.title = 'One'
    edition.start_work
    g.build_edition("Two")
    g
  end

  test 'a new guide has lined_up but isn\'t published' do
    g = Guide.new(:slug=>"childcare")
    assert g.has_lined_up?
    assert !g.has_published?
  end

  test 'when work started a new guide has draft but isn\'t published' do
    g = Guide.new(:slug=>"childcare")
    g.editions.first.start_work
    assert g.has_draft?
    assert !g.has_published?
  end

  test "struct for search index" do
    guide = template_guide
    data = guide.search_index
    assert_equal ["title", "link", "section", "format", "description", "indexable_content", "additional_links"], data.keys
    assert_equal guide.title, data['title']
    assert_equal "guide", data['format']
  end

  test "indexable content contains parts for search index" do
    guide = template_guide
    edition = guide.latest_edition
    edition.parts.build(:body => "ONE", :title => "ONE", :slug => "/one")
    edition.parts.build(:body => "TWO", :title => "TWO", :slug => "/two")
    data = guide.search_index
    assert_equal "ONE ONE TWO TWO", data['indexable_content']
  end

  test "index contains parts as additional links" do
    guide = template_guide
    edition = guide.latest_edition
    edition.parts.build(:body => "ONE", :title => "ONE", :slug => "/one")
    edition.parts.build(:body => "TWO", :title => "TWO", :slug => "/two")
    data = guide.search_index
    assert_equal 2, data['additional_links'].count
  end

  test 'a guide without a video url should not have a video' do
    g = Guide.new(:slug=>"childcare")
    assert !g.has_video?
  end

  test 'a guide with a video url should have a video' do
    g = Guide.new(:slug=>"childcare")
    g.editions.last.video_url = "http://www.youtube.com/watch?v=QH2-TGUlwu4"
    assert g.has_video?
  end

  test 'a guide with all versions published should not have drafts' do
    guide = template_guide
    assert guide.has_draft?
    assert !guide.has_published?
    user = User.create :name => "Winston"

    guide.editions.each do |e|
       e.state = 'ready' #force ready state so that we can publish
       user.publish e, { comment: "Publishing this" }
    end

    assert !guide.has_draft?
    assert guide.has_published?
  end

  test 'a guide with one published and one draft edition is marked as having drafts and having published' do
    guide = template_guide
    assert guide.has_draft?
    assert !guide.has_published?

    guide.editions.first.state = 'ready'
    User.create(:name => "test").publish guide.editions.first, { comment: "Publishing this" }

    assert guide.has_draft?
    assert guide.has_published?
  end

  test "a guide should be marked as having reviewables if requested for review" do
    guide = template_guide
    user = User.create(:name=>"Ben")
    assert !guide.has_in_review?
    user.request_review(guide.editions.first,{:comment => "Review this guide please."})
    assert guide.has_in_review?
  end

  test "guide workflow" do
    user = User.create(:name => "Ben")
    other_user = User.create(:name => "James")

    guide = user.create_publication(:guide)
    edition = guide.editions.first
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

    guide = user.create_publication(:guide)
    edition = guide.editions.first

    assert_equal 0, guide.rejected_count
    assert_equal 0, guide.edition_rejected_count

    user.start_work(edition)
    user.request_review(edition,{:comment => "Review this guide please."})
    other_user.request_amendments(edition, {:comment => "I've reviewed it"})

    assert_equal 1, guide.rejected_count
    assert_equal 1, guide.edition_rejected_count

    user.request_review(edition,{:comment => "Review this guide please."})
    other_user.approve_review(edition, {:comment => "Looks good to me"})

    assert_equal 1, guide.rejected_count
    assert_equal 0, guide.edition_rejected_count
  end

  test "user should be able to have an email sent for fact checking" do
    stub_mailer = stub('mailer', :deliver => true)
    NoisyWorkflow.expects(:request_fact_check).returns(stub_mailer)
    user = User.create(:name => "Ben")

    guide = user.create_publication(:guide)
    edition = guide.editions.first
    edition.state = 'ready'
    assert edition.can_send_fact_check?
    user.send_fact_check(edition, {:email_addresses => "js@alphagov.co.uk, james.stewart@digital.cabinet-office.gov.uk", :customised_message => "Our message"})
  end


  test "user should not be able to review a guide they requested review for" do
    user = User.create(:name => "Ben")

    guide = user.create_publication(:guide)
    edition = guide.editions.first
    user.start_work(edition)
    assert edition.can_request_review?
    user.request_review(edition,{:comment => "Review this guide please."})
    assert ! user.request_amendments(edition, {:comment => "Well Done, but work harder"})
  end

  test "user should not be able to okay a guide they requested review for" do
    user = User.create(:name => "Ben")

    guide = user.create_publication(:guide)
    edition = guide.editions.first
    user.start_work(edition)
    assert edition.can_request_review?
    user.request_review(edition,{:comment => "Review this guide please."})
    assert ! user.approve_review(edition, '')
  end

  test "you can only create a new edition from a published edition" do
    user = User.create(:name => "Ben")

    guide = user.create_publication(:guide)
    edition = guide.editions.first
    assert ! edition.is_published?
    assert ! user.new_version(edition)
  end

  def publisher_and_guide
    user = User.create(:name => "Ben")
    other_user = User.create(:name => "James")

    guide = user.create_publication(:guide, :panopticon_id => 1234574)
    edition = guide.editions.first
    user.start_work(edition)
    user.request_review(edition,{:comment => "Review this guide please."})
    other_user.approve_review(edition, {:comment => "I've reviewed it"})
    user.send_fact_check(edition,{:comment => "Review this guide please.", :email_addresses => 'test@test.com'})
    user.receive_fact_check(edition, {:comment => "No changes needed, this is all correct"})
    other_user.approve_fact_check(edition, {:comment => "Looks good to me"})
    user.publish(edition, {:comment => "PUBLISHED!"})
    return user, guide
  end

  test "a guide should not send an email if creating a new edition fails" do
    user, guide = publisher_and_guide
    edition = guide.published_edition
    NoisyWorkflow.expects(:make_noise).never
    edition.expects(:build_clone).returns(false)
    assert ! user.new_version(edition)
  end
end
