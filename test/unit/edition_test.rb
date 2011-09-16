require 'test_helper'


class EditionTest < ActiveSupport::TestCase

  def template_edition
    g = Guide.new(:name => "CHILDCARE", :slug=>"childcare")
    edition = g.editions.first
    edition.parts.build(:title => 'PART !', :body=>"This is some version text.", :slug => 'part-one')
    edition.parts.build(:title => 'PART !!', :body=>"This is some more version text.", :slug => 'part-two')
    edition
  end

  test "editions, by default, return their title for use in the admin-interface lists of publications" do
    assert_equal template_edition.title, template_edition.admin_list_title
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
    without_panopticon_validation do
      guide = template_edition.guide
      guide.save
      assert_nil guide.published_edition
    end
  end

  test "an edition of a guide can be published" do
    edition = template_edition
    guide = template_edition.guide
    stub_request(:get, "http://panopticon.test.gov.uk/artefacts/childcare.js").
      to_return(:status => 200, :body => '{"name":"Childcare","slug":"childcare"}', :headers => {})
    guide.publish edition,"Published because I did"
    assert_not_nil guide.published_edition
  end

  test "a published edition can't be edited" do
    without_panopticon_validation do
      edition = template_edition
      guide = template_edition.container
      guide.save

      stub_request(:get, "http://panopticon.test.gov.uk/artefacts/childcare.js").
        to_return(:status => 200, :body => '{"name":"Childcare","slug":"childcare"}', :headers => {})

      guide.publish edition, "Published because I did"
      guide.reload

      edition = guide.editions.last
      edition.title = "My New Title"

      assert ! edition.save
      assert_equal ["Published editions can't be edited"], edition.errors[:base]
    end
  end

  test "publish history is recorded" do
    without_panopticon_validation do
      edition = template_edition
      guide = template_edition.guide
      guide.save

      stub_request(:get, "http://panopticon.test.gov.uk/artefacts/childcare.js").
        to_return(:status => 200, :body => '{"name":"Childcare","slug":"childcare"}', :headers => {})

      guide.publish edition, "First publication"
      guide.publish edition, "Second publication"

      new_edition = edition.build_clone
      new_edition.parts.first.body = "Some other version text"

      guide.publish new_edition, "Third publication"

      assert_equal 3, guide.publishings.length
    end

  end
end
