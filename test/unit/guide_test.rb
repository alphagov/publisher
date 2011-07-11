require 'test_helper'


class GuideTest < ActiveSupport::TestCase

  def template_guide
    g = Guide.new(:slug=>"childcare")
    edition = g.editions.first
    edition.title = 'One'
    g.build_edition("Two","New edition")
    g
  end
  
  test 'guides assume the title of their latest edition' do
    assert_equal template_guide.title, 'Two'
  end
  
  test 'a new guide has drafts but isn\'t published' do
    g = Guide.new(:slug=>"childcare")
    assert g.has_drafts
    assert !g.has_published
  end
  
  test 'a guide with all versions published should not have drafts' do
    guide = template_guide
    assert guide.has_drafts
    assert !guide.has_published
    
    guide.editions.each do |e|
       guide.publish e, "Publishing this"
    end
    
    assert !guide.has_drafts
    assert guide.has_published
  end
  
  test 'a guide with one published and one draft edition is marked as having drafts and having published' do
    guide = template_guide
    assert guide.has_drafts
    assert !guide.has_published
    
    guide.publish guide.editions.first, "Publishing this"
    
    assert guide.has_drafts
    assert guide.has_published
  end
   
  test "a guide should be marked as having reviewables if requested for review" do
    guide = template_guide
    user = User.new(:name=>"Ben")
    assert !guide.has_reviewables
    user.request_review(guide.editions.first,"Review this guide please.")
    assert guide.has_reviewables
  end
  
  test "guide workflow" do
    user = User.new(:name=>"Ben")
    guide = user.create_guide
    edition = guide.editions.first
    assert edition.can_request_review?
    user.request_review(edition,"Review this guide please.")
    assert !edition.can_request_review?
    assert edition.can_review?
    user.review(edition,"I've reviewed it")
    assert !edition.can_review?
    user.request_review(edition,"Review this guide please.")
    assert edition.can_okay?
    user.okay(edition,"Looks good to me")
    assert edition.can_publish?
  end
  
end