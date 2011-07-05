require 'test_helper'


class EditionTest < ActiveSupport::TestCase

  def template_edition
    g = Guide.new(:slug=>"childcare")
    edition = g.editions.first
    edition.parts.build(:body=>"This is some version text.")
    edition.parts.build(:body=>"This is some more version text.")
    edition
  end

  test "guides have at least one edition" do
    g = Guide.new(:slug=>"childcare")
    assert_equal 1, g.editions.length 
  end

  test "new edition should have an incremented version number" do
    g = Guide.new(:slug=>"childcare")
    edition = g.editions.first
    new_edition = edition.build_clone
    assert_equal edition.version_number + 1, new_edition.version_number
  end
  
  test "new editions should have the same text when created" do
    edition = template_edition
    new_edition = edition.build_clone
    original_text = edition.parts.map {|p| p.body }.join(" ")
    new_text = new_edition.parts.map  {|p| p.body }.join(" ")
    assert_equal original_text,new_text
  end
  
  test "changing text in a new edition should not change text in old edition" do
    edition = template_edition
    new_edition = edition.build_clone
    new_edition.parts.first.body = "Some other version text"
    original_text = edition.parts.map     {|p| p.body }.join(" ")
    new_text =      new_edition.parts.map {|p| p.body }.join(" ")
    assert_not_equal original_text,new_text
  end
  
  test "a new guide has no published edition" do
    guide = template_edition.guide
    guide.save
    assert_nil guide.published_edition
  end
    
  test "an edition of a guide can be published" do
    edition = template_edition
    guide = template_edition.guide
    guide.publish! edition,"Published because I did"
    assert_not_nil guide.published_edition
  end
  
  test "publish history is recorded" do
    edition = template_edition
    guide = template_edition.guide
    guide.save
    
    guide.publish! edition, "First publication"
    guide.publish! edition, "Second publication"
    
    new_edition = edition.build_clone
    new_edition.parts.first.body = "Some other version text"
    
    guide.publish! new_edition, "Third publication"
    
    puts "HELLO #{guide.publishings}"
  end
  
end
