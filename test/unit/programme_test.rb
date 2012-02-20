require 'test_helper'

class ProgrammeTest < ActiveSupport::TestCase

  setup do
    stub_request(:get, /.*panopticon\.test\.gov\.uk\/artefacts\/.*\.js/).
      to_return(:status => 200, :body => "{}", :headers => {})
  end

  def template_programme
    p = unpublished_template_programme
    edition = p.editions.first
    edition.state = :ready
    edition.save
    User.create(:name => 'dai').publish(edition, comment: "Publishing this")
    p
  end
  
  def unpublished_template_programme
    p = Programme.new(:slug=>"childcare", :name=>"Children", :panopticon_id => 987353)
    edition = p.editions.first
    edition.title = 'One'
    edition.start_work
    edition.save
    p
  end

  test 'a new programme has drafts but isn\'t published' do
    p = Programme.new(:slug=>"childcare", :name => "Children", :panopticon_id => 987353)
    p.editions.first.start_work
    assert p.has_draft?
    assert !p.has_published?
  end

  test 'a programme with all versions published should not have drafts' do
    programme = template_programme

    assert !programme.has_draft?
    assert programme.has_published?
  end

  test 'a programme correctly formats the additional links' do
    programme = template_programme
    out = programme.search_index
    assert_equal 5, out['additional_links'].count
    assert_equal '/childcare#overview', out['additional_links'].first['link']
    assert_equal '/childcare/further-information', out['additional_links'].last['link']
  end

  test 'a programme with one published and one draft edition is marked as having drafts and having published' do
    programme = template_programme
    programme.build_edition("Two")
    
    assert programme.has_draft?
    assert programme.has_published?
  end

  test "a programme should be marked as having reviewables if requested for review" do
    programme = unpublished_template_programme
    user = User.new(:name=>"Bob")
    user.save
    assert !programme.has_in_review?
    user.request_review(programme.editions.first,{:comment => "Review this programme please."})
    assert programme.has_in_review?, "A review was not requested for this programme."
  end

  test "programme workflow" do
    user = User.create(:name => "Bob")
    other_user = User.create(:name => "James")

    programme = user.create_publication(:programme)
    edition = programme.editions.first
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

  test "user should not be able to review a programme they requested review for" do
    user = User.create(:name => "Bob")

    programme = user.create_publication(:programme)
    edition = programme.editions.first
    user.start_work(edition)
    assert edition.can_request_review?
    user.request_review(edition,{:comment => "Review this programme please."})
    assert ! user.request_amendments(edition, {:comment => "Well Done, but work harder"})
  end

  test "user should not be able to okay a programme they requested review for" do
    user = User.create(:name => "Bob")

    programme = user.create_publication(:programme)
    edition = programme.editions.first
    user.start_work(edition)
    assert edition.can_request_review?
    user.request_review(edition,{:comment => "Review this programme please."})
    assert ! user.approve_review(edition, '')
  end

  test "you can only create a new edition from a published edition" do
    user = User.create(:name => "Bob")

    programme = user.create_publication(:programme)
    edition = programme.editions.first
    assert ! edition.is_published?
    assert ! user.new_version(edition)
  end

  test "new programme has default parts" do
    programme = template_programme
    assert_equal 1, programme.editions.length
    assert_equal 5, programme.editions.first.parts.length
  end

  test "new programme has correct parts" do
    programme = template_programme
    Programme::DEFAULT_PARTS.each_with_index{ |part, index|
      assert_equal part[:title], programme.editions.first.parts[index].title
    }
  end

end
