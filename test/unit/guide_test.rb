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
   
end