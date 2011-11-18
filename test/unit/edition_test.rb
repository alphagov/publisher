require 'test_helper'

class EditionTest < ActiveSupport::TestCase

  def template_edition
    g = Guide.new(:name => "CHILDCARE", :slug=>"childcare")
    edition = g.editions.first
    edition.parts.build(:title => 'PART !', :body=>"This is some version text.", :slug => 'part-one')
    edition.parts.build(:title => 'PART !!', :body=>"This is some more version text.", :slug => 'part-two')
    edition
  end

  setup do
    stub_request(:get, "http://panopticon.test.gov.uk/artefacts/childcare.js").
      to_return(:status => 200, :body => '{"name":"Childcare","slug":"childcare"}', :headers => {})
  end

  test "editions, by default, return their title for use in the admin-interface lists of publications" do
    assert_equal template_edition.title, template_edition.admin_list_title
  end

  test "guides have at least one edition" do
    g = Guide.new(:slug=>"childcare")
    assert_equal 1, g.editions.length
  end

  test "editions can have notes stored for the history tab" do
    edition = template_edition
    user = User.new
    assert edition.new_action(user, 'note', comment: 'Something important')
  end

  test "status should not be affected by notes" do
    user = User.create(:name => "bob")
    edition = template_edition
    t0 = Time.now
    Timecop.freeze(t0) do
      edition.new_action(user, Action::OKAYED)
    end
    Timecop.freeze(t0 + 1) do
      edition.new_action(user, Action::NOTE, comment: 'Something important')
    end
    assert_equal Action::OKAYED, edition.latest_status_action.request_type
  end

  test "should have no assignee by default" do
    edition = template_edition
    assert_nil edition.assigned_to
  end

  test "should be assigned to the last assigned recipient" do
    alice = User.create(:name => "alice")
    bob   = User.create(:name => "bob")
    edition = template_edition
    alice.assign(edition, bob)
    assert_equal bob, edition.assigned_to
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
    assert_equal original_text, new_text
  end

  test "changing text in a new edition should not change text in old edition" do
    edition = template_edition
    new_edition = edition.build_clone
    new_edition.parts.first.body = "Some other version text"
    original_text = edition.parts.map     {|p| p.body }.join(" ")
    new_text =      new_edition.parts.map {|p| p.body }.join(" ")
    assert_not_equal original_text, new_text
  end

  test "a new guide has no published edition" do
    without_metadata_denormalisation(Guide) do
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
    without_metadata_denormalisation(Guide) do
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
    without_metadata_denormalisation(Guide) do
      edition = template_edition
      guide = template_edition.guide
      guide.save

      guide.publish edition, "First publication"
      guide.publish edition, "Second publication"

      new_edition = edition.build_clone
      new_edition.parts.first.body = "Some other version text"

      guide.publish new_edition, "Third publication"

      assert_equal 3, guide.publishings.length
    end

  end
end
