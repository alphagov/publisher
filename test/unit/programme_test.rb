require 'test_helper'

class ProgrammeTest < ActiveSupport::TestCase

  setup do
    stub_request(:get, "http://panopticon.test.gov.uk/artefacts/987353.js").
      to_return(:status => 200, :body => "{}", :headers => {})
  end

  def template_programme
    p = Programme.new(:slug=>"childcare", :name=>"Children", :panopticon_id => 987353)
    edition = p.editions.first
    edition.title = 'One'
    p
  end

  test 'a new programme has drafts but isn\'t published' do
    p = Programme.new(:slug=>"childcare", :name => "Children", :panopticon_id => 987353)
    assert p.has_drafts
    assert !p.has_published
  end

  test 'a programme with all versions published should not have drafts' do
    programme = template_programme
    assert programme.has_drafts
    assert !programme.has_published

    programme.editions.each do |e|
       programme.publish e, "Publishing this"
    end

    assert !programme.has_drafts
    assert programme.has_published
  end

  test 'a programme with one published and one draft edition is marked as having drafts and having published' do
    programme = template_programme
    programme.build_edition("Two")
    assert programme.has_drafts
    assert !programme.has_published
    programme.publish programme.editions.first, "Publishing this"
    assert programme.has_drafts
    assert programme.has_published
  end

  test "a programme should be marked as having reviewables if requested for review" do
    programme = template_programme
    user = User.new(:name=>"Bob")
    user.save
    assert !programme.has_reviewables
    user.request_review(programme.editions.first,{:comment => "Review this programme please."})
    assert programme.has_reviewables
  end

  test "programme workflow" do
    user = User.create(:name => "Bob")
    other_user = User.create(:name => "James")

    programme = user.create_programme
    edition = programme.editions.first
    assert edition.can_request_review?
    user.request_review(edition, {:comment => "Review this programme please."})
    assert !edition.can_request_review?
    assert edition.can_review?
    other_user.review(edition, {:comment => "I've reviewed it"})
    assert !edition.can_review?
    user.request_review(edition, {:comment => "Review this programme please."})
    assert edition.can_okay?
    other_user.okay(edition, {:comment => "Looks good to me"})
    assert edition.can_publish?
  end

  test "user should not be able to review a programme they requested review for" do
    user = User.create(:name => "Bob")

    programme = user.create_programme
    edition = programme.editions.first
    assert edition.can_request_review?
    user.request_review(edition,{:comment => "Review this programme please."})
    assert ! user.review(edition, {:comment => "Well Done, but work harder"})
  end

  test "user should not be able to okay a programme they requested review for" do
    user = User.create(:name => "Bob")

    programme = user.create_programme
    edition = programme.editions.first
    assert edition.can_request_review?
    user.request_review(edition,{:comment => "Review this programme please."})
    assert ! user.okay(edition, '')
  end

  test "you can only create a new edition from a published edition" do
    user = User.create(:name => "Bob")

    programme = user.create_programme
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
