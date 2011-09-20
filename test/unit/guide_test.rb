require 'test_helper'

class GuideTest < ActiveSupport::TestCase

  def template_guide
    g = Guide.new(:slug=>"childcare",:name=>"Something")
    edition = g.editions.first
    edition.title = 'One'
    g.build_edition("Two")
    g
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
    user.save
    assert !guide.has_reviewables
    user.request_review(guide.editions.first,"Review this guide please.")
    assert guide.has_reviewables
  end
  
  test "guide workflow" do
    user = User.create(:name => "Ben")
    other_user = User.create(:name => "James")
    
    guide = user.create_guide
    edition = guide.editions.first
    assert edition.can_request_review?
    user.request_review(edition,"Review this guide please.")
    assert !edition.can_request_review?
    assert edition.can_review?
    other_user.review(edition,"I've reviewed it")
    assert !edition.can_review?
    user.request_review(edition,"Review this guide please.")
    assert edition.can_okay?
    other_user.okay(edition,"Looks good to me")
    assert edition.can_publish?
  end
  
  test "user should be able to have an email sent for fact checking" do
    stub_mailer = stub('mailer', :deliver => true)
    NoisyWorkflow.expects(:request_fact_check).returns(stub_mailer)
    user = User.create(:name => "Ben")

    guide = user.create_guide
    edition = guide.editions.first
    assert edition.can_request_fact_check?
    user.request_fact_check(edition, "js@alphagov.co.uk, james.stewart@digital.cabinet-office.gov.uk")
  end

  test "user should not be able to request review for a guide that's being fact checked" do
    user = User.create(:name => "Ben")
  
    guide = user.create_guide
    edition = guide.editions.first
    user.request_fact_check(edition, "js@alphagov.co.uk, james.stewart@digital.cabinet-office.gov.uk")
    assert ! edition.can_request_review?
  end
  
  test "user should not be able to review a guide they requested review for" do
    user = User.create(:name => "Ben")
  
    guide = user.create_guide
    edition = guide.editions.first
    assert edition.can_request_review?
    user.request_review(edition,"Review this guide please.")
    assert ! user.review(edition, "Well Done, but work harder")
  end
  
  test "user should not be able to okay a guide they requested review for" do
    user = User.create(:name => "Ben")
  
    guide = user.create_guide
    edition = guide.editions.first
    assert edition.can_request_review?
    user.request_review(edition,"Review this guide please.")
    assert ! user.okay(edition, '')
  end
  
  test "you can only create a new edition from a published edition" do
    user = User.create(:name => "Ben")
  
    guide = user.create_guide
    edition = guide.editions.first
    assert ! edition.is_published?
    assert ! user.new_version(edition)
  end
    
end