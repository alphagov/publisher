require 'test_helper'

class ProgrammeEditionTest < ActiveSupport::TestCase
  def template_programme
    g = Programme.new(:slug=>"childcare", :name=>"Something")
    edition = g.editions.first
    edition.title = 'One'
    g
  end

  test "order parts shouldn't fail if one part's order attribute is nil" do
    g = template_programme
    edition = g.editions.first
    edition.parts.build
    edition.parts.build(:order => 1)
    assert edition.order_parts
  end

  setup do
    stub_request(:get, /.*panopticon\.test\.gov\.uk\/artefacts\/.*\.js/).
      to_return(:status => 200, :body => "{}", :headers => {})
  end

  def template_programme
    p = ProgrammeEdition.new(:slug=>"childcare", :title=>"Children", :panopticon_id => 987353)
    p.start_work
    p.save
    p
  end

  def template_users
    user = User.create(:name => "Bob")
    other_user = User.create(:name => "James")
    return user, other_user
  end

  test 'a new programme has drafts but isn\'t published' do
    p = template_programme
    assert p.draft?
    assert ! p.published?
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
    assert !programme.has_published?
    programme.editions.first.state = 'ready'
    User.create(:name => 'bob').publish(programme.editions.first, comment: "Publishing this")
    assert programme.has_draft?
    assert programme.has_published?
  end

  test "a programme should be marked as having reviewables if requested for review" do
    programme = template_programme
    user, other_user = template_users

    assert !programme.in_review?
    user.request_review(programme.editions.first,{:comment => "Review this programme please."})
    assert programme.has_in_review?, "A review was not requested for this programme."
  end

  test "programme workflow" do
    user, other_user = template_users

    edition = user.create_whole_edition(:programme)
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
    user, other_user = template_users

    edition = user.create_whole_edition(:programme)
    user.start_work(edition)
    edition.save
    
    assert edition.can_request_review?

    user.request_review(edition, {:comment => "Review this programme please."})
    assert ! user.request_amendments(edition, {:comment => "Well Done, but work harder"})
  end

  test "user should not be able to okay a programme they requested review for" do
    user, other_user = template_users

    edition = user.create_whole_edition(:programme)
    user.start_work(edition)
    assert edition.can_request_review?
    user.request_review(edition,{:comment => "Review this programme please."})
    assert ! user.approve_review(edition, '')
  end

  test "you can only create a new edition from a published edition" do
    user, other_user = template_users

    edition = user.create_whole_edition(:programme)
    assert ! edition.published?
    assert ! user.new_version(edition)
  end

  test "new programme has correct parts" do
    programme = template_programme
    assert_equal 5, programme.parts.length
    Programme::DEFAULT_PARTS.each_with_index { |part, index|
      assert_equal part[:title], programme.parts[index].title
    }
  end

end
