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
  
  test "struct for search index" do
    edition = template_guide
    edition.update_attribute(:state, 'published')
    data = edition.search_index
    assert_equal ["title", "link", "format", "description", "indexable_content", "section", "subsection", "additional_links"], data.keys
    assert_equal edition.title, data['title']
    assert_equal "guide", data['format']
  end

  test "indexable content contains parts for search index" do
    edition = template_guide
    edition.update_attribute(:state, 'published')
    edition.parts.build(:body => "ONE", :title => "ONE", :slug => "/one")
    edition.parts.build(:body => "TWO", :title => "TWO", :slug => "/two")
    data = edition.search_index
    assert_equal "ONE ONE TWO TWO", data['indexable_content']
  end

  test "index contains parts as additional links on published guide" do
    edition = template_guide
    edition.update_attribute(:state, 'published')
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