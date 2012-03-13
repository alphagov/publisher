require 'test_helper'

class EditionTest < ActiveSupport::TestCase

  def template_edition
    g = FactoryGirl.create(:guide_edition)
    g.parts.build(:title => 'PART !', :body=>"This is some version text.", :slug => 'part-one')
    g.parts.build(:title => 'PART !!', :body=>"This is some more version text.", :slug => 'part-two')
    g
  end

  setup do
    panopticon_has_metadata("id" => '2356', "slug" => 'childcare',"name" => "Childcare")
  end

  test "editions, by default, return their title for use in the admin-interface lists of publications" do
    my_edition = template_edition
    assert_equal my_edition.title, my_edition.admin_list_title
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
      edition.new_action(user, Action::APPROVE_REVIEW)
    end
    Timecop.freeze(t0 + 1) do
      edition.new_action(user, Action::NOTE, comment: 'Something important')
    end
    assert_equal Action::APPROVE_REVIEW, edition.latest_status_action.request_type
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
    edition = FactoryGirl.create(:guide_edition)
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
    guide = template_edition
    guide.save
    assert_nil GuideEdition.where(state: 'published', panopticon_id: guide.panopticon_id).first
  end

  test "a draft edition cannot be published" do
    edition = template_edition
    guide = template_edition.guide
    guide.editions.first.update_attribute :state, 'draft'

    assert_false guide.editions.first.can_publish?
  end

  test "a draft edition can be emergency published" do
    edition = template_edition
    guide = template_edition.guide
    guide.editions.first.update_attribute :state, 'draft'

    assert guide.editions.first.can_emergency_publish?
  end

  test "an edition of a guide can be published" do
    edition = template_edition
    edition.update_attribute :state, 'ready'
    edition.publish
    assert_not_nil GuideEdition.where(state: 'published', panopticon_id: edition.panopticon_id).first
  end

  test "when an edition of a guide is published, all other published editions are archived" do
    without_metadata_denormalisation(GuideEdition) do
      edition = template_edition
      
      user = User.create :name => 'bob'
      edition.save                

      edition.update_attribute(:state, 'ready')
      user.publish edition, comment: "First publication"      

      second_edition = edition.build_clone
      second_edition.save!
      second_edition.update_attribute(:state, 'ready')
      user.publish second_edition, comment: "Second publication"  

      third_edition = second_edition.build_clone
      third_edition.save!
      third_edition.update_attribute(:state, 'ready')                 
      user.publish third_edition, comment: "Third publication"

      edition.reload
      assert edition.archived?
      
      second_edition.reload
      assert second_edition.archived?
      
      assert_equal 2, GuideEdition.where(panopticon_id: edition.panopticon_id, state: 'archived').count
    end
  end    
  
  test "edition can return latest status action of a specified request type" do
    edition = template_edition
    user = User.create(:name => 'George')
    edition.save

    edition.update_attribute :state, 'draft'
    edition.reload                                         
    
    user.request_review edition, comment: "Requesting review" 
    
    assert_equal edition.actions.size, 1
    assert edition.latest_status_action(Action::REQUEST_REVIEW).present?
  end

  test "a published edition can't be edited" do
    guide = template_edition
    guide.save

    guide.update_attribute :state, 'published'
    guide.reload

    guide.title = "My New Title"

    assert ! guide.save
    assert_equal ["Published editions can't be edited"], guide.errors[:base]
  end

  test "publish history is recorded" do
    without_metadata_denormalisation(GuideEdition) do
      edition = template_edition
      
      user = User.create :name => 'bob'
      edition.save                

      edition.update_attribute(:state, 'ready')
      user.publish edition, comment: "First publication"

      second_edition = edition.build_clone
      second_edition.save!
      second_edition.update_attribute(:state, 'ready')
      user.publish second_edition, comment: "Second publication"

      third_edition = second_edition.build_clone
      third_edition.save!
      third_edition.update_attribute(:state, 'ready')
      user.publish third_edition, comment: "Third publication"

      edition.reload
      assert edition.actions.where('request_type' => 'publish')

      second_edition.reload
      assert second_edition.actions.where('request_type' => 'publish')
      
      third_edition.reload
      assert third_edition.actions.where('request_type' => 'publish')
      assert third_edition.published?
    end
  end

  test "a new edition contains a diff when published" do
    without_metadata_denormalisation(Guide) do
      guide = Guide.new(:name => "One", :slug=>"one")
      guide.save!

      user = User.create :name => 'Silvia'

      edition_one = guide.editions.first
      edition_one.parts.build :title => 'Part One', :body=>"It was on a cold day in March", :slug => 'part-one'
      edition_one.save!
      edition_one.state = :ready
      user.publish edition_one, comment: "First edition"

      edition_two = edition_one.build_clone
      edition_two.save!
      edition_two.parts.first.update_attribute :body, "It was on a cold day in April"
      edition_two.state = :ready
      user.publish edition_two, comment: "Second edition"

      publish_action = edition_two.actions.where(request_type: "publish").last

      assert_equal "# Part One\n\n{\"It was on a cold day in March\" >> \"It was on a cold day in April\"}", publish_action.diff
    end
  end
end
