require 'test_helper'

class WholeEditionTest < ActiveSupport::TestCase
  setup do
    panopticon_has_metadata("id" => '2356', "kind" => "answer", "slug" => 'childcare', "name" => "Childcare")
  end

  def template_answer(version_number = 1)
    AnswerEdition.create(state: 'ready', slug: "childcare", panopticon_id: 1,
      title: 'Child care stuff', body: 'Lots of info', version_number: version_number)
  end

  def template_published_answer(version_number = 1)
    answer = template_answer(version_number)
    answer.publish
    answer.save
    answer
  end

  def template_transaction
    TransactionEdition.create(title: 'One', introduction: 'introduction',
      more_information: 'more info', panopticon_id: 2, slug: "childcare")
  end

  def template_unpublished_answer(version_number = 1)
    template_answer(version_number)
  end

  test "it must have a title" do
    a = LocalTransactionEdition.new
    assert ! a.valid?
    assert a.errors[:title].any?
  end

  test "it should give a friendly (legacy supporting) description of its format" do
    a = LocalTransactionEdition.new
    assert_equal 'LocalTransaction', a.format
  end

  test "it should be able to find its siblings" do
    g1 = FactoryGirl.create(:guide_edition, :panopticon_id => 1, :version_number => 1)
    g2 = FactoryGirl.create(:guide_edition, :panopticon_id => 2, :version_number => 1)
    g3 = FactoryGirl.create(:guide_edition, :panopticon_id => 1, :version_number => 2)
    assert_equal [], g2.siblings.to_a
    assert_equal [g3], g1.siblings.to_a
  end

  test "it should be able to find its previous siblings" do
    g1 = FactoryGirl.create(:guide_edition, :panopticon_id => 1, :version_number => 1)
    g2 = FactoryGirl.create(:guide_edition, :panopticon_id => 2, :version_number => 1)
    g3 = FactoryGirl.create(:guide_edition, :panopticon_id => 1, :version_number => 2)

    assert_equal [], g1.previous_siblings.to_a
    assert_equal [g1], g3.previous_siblings.to_a
  end

  test "edition finder should return the published edition when given an empty edition parameter" do
    dummy_publication = template_published_answer
    second_publication = template_unpublished_answer(2)

    assert dummy_publication.published?
    assert_equal dummy_publication, WholeEdition.find_and_identify('childcare', '')
  end

  test "edition finder should return the latest edition when asked" do
    dummy_publication = template_published_answer
    second_publication = template_unpublished_answer(2)

    assert_equal 2, WholeEdition.where(slug: dummy_publication.slug).count
    found_edition = WholeEdition.find_and_identify('childcare', 'latest')
    assert_equal second_publication.version_number, found_edition.version_number
  end

  test "struct for search index" do
    dummy_publication = template_published_answer
    out = dummy_publication.search_index
    assert_equal ["title", "link", "format", "description", "indexable_content", "section", "subsection"], out.keys
  end

  test "search index for all publications" do
    dummy_publication = template_published_answer
    out = WholeEdition.search_index_all
    assert_equal 1, out.count
    assert_equal ["title", "link", "format", "description", "indexable_content", "section", "subsection"], out.first.keys
  end

  test "search indexable content for answer" do
    dummy_publication = template_published_answer
    assert_equal dummy_publication.indexable_content, "Lots of info"
  end

  test "search indexable content for transaction" do
    dummy_publication = template_transaction
    assert_equal dummy_publication.indexable_content, "introduction more info"
  end

  test 'a publication should not have a video' do
    dummy_publication = template_published_answer
    assert !dummy_publication.has_video?
  end

  test "should create a publication based on data imported from panopticon" do
    panopticon_has_metadata(
        "id" => 2356,
        "slug" => "foo-bar",
        "kind" => "answer",
        "name" => "Foo bar"
    )

    user = User.create

    publication = WholeEdition.create_from_panopticon_data(2356, user)

    assert_kind_of AnswerEdition, publication
    assert_equal "Foo bar", publication.title
    assert_equal 2356, publication.panopticon_id
  end

  test "should not change edition name if published" do
    guide = Factory(:guide_edition,
                    panopticon_id: 2356,
                    title: "Original title",
                    slug: "original-title"
    )
    guide.state = 'ready'
    guide.save!
    User.create(:name => "Winston").publish(guide, comment: 'testing')

    panopticon_has_metadata(
        "id" => 2356,
        "slug" => "foo-bar",
        "kind" => "guide",
        "name" => "New title"
    )
    guide.save!

    assert_equal "Original title", guide.reload.title
  end

  test "should scope publications by assignee" do
    stub_request(:get, %r{http://panopticon\.test\.gov\.uk/artefacts/.*\.js}).
        to_return(:status => 200, :body => "{}", :headers => {})

    a, b = 2.times.map { FactoryGirl.create(:guide_edition) }

    alice, bob, charlie = %w[ alice bob charlie ].map { |s|
      FactoryGirl.create(:user, name: s)
    }
    alice.assign(a, bob)
    alice.assign(a, charlie)
    alice.assign(b, bob)

    assert_equal [b], WholeEdition.assigned_to(bob).to_a
  end

  test "cannot delete a publication that has been published" do
    dummy_answer = template_published_answer
    loaded_answer = AnswerEdition.where(slug: 'childcare').first

    assert_equal loaded_answer, dummy_answer
    assert ! dummy_answer.can_destroy?
    assert_raise (Workflow::CannotDeletePublishedPublication) do
      dummy_answer.destroy
    end
  end

  test "cannot delete a published publication with a new draft edition" do
    dummy_answer = template_published_answer

    new_edition = dummy_answer.build_clone
    new_edition.body = 'Two'
    dummy_answer.save

    assert_raise (WholeEdition::CannotDeletePublishedPublication) do
      dummy_answer.destroy
    end
  end

  test "can delete a publication that has not been published" do
    dummy_answer = template_unpublished_answer
    dummy_answer.destroy

    loaded_answer = AnswerEdition.where(slug: dummy_answer.slug).first
    assert_nil loaded_answer
  end

  test "should scope publications assigned to nobody" do
    stub_request(:get, %r{http://panopticon\.test\.gov\.uk/artefacts/.*\.js}).
        to_return(:status => 200, :body => "{}", :headers => {})

    Rails.logger.warn "MONGODB: ABout to create two guides"
    a, b = 2.times.map { |i| GuideEdition.create!(panopticon_id: i, title: "Guide #{i}", slug: "guide-#{i}") }
    Rails.logger.warn "MONGODB: Done creating two guides"

    alice, bob, charlie = %w[ alice bob charlie ].map { |s|
      FactoryGirl.create(:user, name: s)
    }

    alice.assign(a, bob)
    a.reload
    assert_equal bob, a.assigned_to

    alice.assign(a, charlie)
    a.reload
    assert_equal charlie, a.assigned_to

    assert_equal 2, WholeEdition.count
    assert_equal [b], WholeEdition.assigned_to(nil).to_a
    assert_equal [], WholeEdition.assigned_to(bob).to_a
    assert_equal [a], WholeEdition.assigned_to(charlie).to_a
  end

  test "should update Rummager on publication with no parts" do
    edition = FactoryGirl.create(:guide_edition, :state => 'ready')
    edition.stubs(:search_index).returns("stuff for search index")

    Rummageable.expects(:index).with("stuff for search index")
    user = FactoryGirl.create(:user)
    user.publish(edition, comment: 'Testing')
  end

  test "search_index for a single part thing should have the normalised content of that part" do
    edition = FactoryGirl.create(:guide_edition, :state => 'ready', :title => 'one part thing', :alternative_title => 'alternative one part thing')
    edition.publish
    generated_search_content = edition.search_index
    assert_equal generated_search_content['indexable_content'], "alternative one part thing"
    assert_equal generated_search_content['additional_links'].length, 0
  end

  test "search_index for a multi part thing should have the normalised content of all parts" do
    edition = FactoryGirl.create(:guide_edition_with_two_parts, :state => 'ready')
    edition.publish
    generated_search_content = edition.search_index
    assert_equal generated_search_content['indexable_content'], "PART ! This is some version text. PART !! This is some more version text."
    assert generated_search_content['additional_links'][1].has_value?("/#{edition.slug}/part-two")
  end

  test "should update Rummager on deletion" do
    publication = FactoryGirl.create(:guide_edition, :slug => "hedgehog-topiary")
    Rummageable.expects(:delete).with("/hedgehog-topiary")
    publication.destroy
  end

  test "given multiple editions, can return the most recent published edition" do
    publication = FactoryGirl.create(:guide_edition, :slug => "hedgehog-topiary", :state => 'archived')

    second_edition = publication.build_clone
    second_edition.update_attribute(:state, 'published')

    third_edition = second_edition.build_clone
    third_edition.update_attribute(:state, 'draft')

    assert_equal publication.published_edition, second_edition
  end

  test "editions, by default, return their title for use in the admin-interface lists of publications" do
    edition = FactoryGirl.create(:guide_edition, :state => 'ready')
    assert_equal edition.title, edition.admin_list_title
  end

  test "editions can have notes stored for the history tab" do
    edition = FactoryGirl.create(:guide_edition, :state => 'ready')
    user = User.new
    assert edition.new_action(user, 'note', comment: 'Something important')
  end

  test "status should not be affected by notes" do
    user = User.create(:name => "bob")
    edition = FactoryGirl.create(:guide_edition, :state => 'ready')
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
    edition = FactoryGirl.create(:guide_edition, :state => 'ready')
    assert_nil edition.assigned_to
  end

  test "should be assigned to the last assigned recipient" do
    alice = User.create(:name => "alice")
    bob = User.create(:name => "bob")
    edition = FactoryGirl.create(:guide_edition, :state => 'ready')
    alice.assign(edition, bob)
    assert_equal bob, edition.assigned_to
  end

  test "new edition should have an incremented version number" do
    edition = FactoryGirl.create(:guide_edition)
    new_edition = edition.build_clone
    assert_equal edition.version_number + 1, new_edition.version_number
  end

  test "new edition should have an empty list of actions" do
    edition = FactoryGirl.create(:guide_edition)
    new_edition = edition.build_clone
    assert_equal [], new_edition.actions
  end

  test "new editions should have the same text when created" do
    edition = FactoryGirl.create(:guide_edition_with_two_parts, :state => 'ready')
    new_edition = edition.build_clone
    original_text = edition.parts.map {|p| p.body }.join(" ")
    new_text = new_edition.parts.map {|p| p.body }.join(" ")
    assert_equal original_text, new_text
  end

  test "changing text in a new edition should not change text in old edition" do
    edition = FactoryGirl.create(:guide_edition_with_two_parts, :state => 'ready')
    new_edition = edition.build_clone
    new_edition.parts.first.body = "Some other version text"
    original_text = edition.parts.map {|p| p.body }.join(" ")
    new_text = new_edition.parts.map {|p| p.body }.join(" ")
    assert_not_equal original_text, new_text
  end

  test "a new guide has no published edition" do
    guide = FactoryGirl.create(:guide_edition, :state => 'ready')
    assert_nil GuideEdition.where(state: 'published', panopticon_id: guide.panopticon_id).first
  end

  test "an edition of a guide can be published" do
    edition = FactoryGirl.create(:guide_edition, :state => 'ready')
    edition.publish
    assert_not_nil GuideEdition.where(state: 'published', panopticon_id: edition.panopticon_id).first
  end

  test "when an edition of a guide is published, all other published editions are archived" do
    without_metadata_denormalisation(GuideEdition) do
      edition = FactoryGirl.create(:guide_edition, :state => 'ready')

      user = User.create :name => 'bob'
      user.publish edition, comment: "First publication"

      second_edition = edition.build_clone
      second_edition.update_attribute(:state, 'ready')
      second_edition.save!
      user.publish second_edition, comment: "Second publication"

      third_edition = second_edition.build_clone
      third_edition.update_attribute(:state, 'ready')
      third_edition.save!
      user.publish third_edition, comment: "Third publication"

      edition.reload
      assert edition.archived?

      second_edition.reload
      assert second_edition.archived?

      assert_equal 2, GuideEdition.where(panopticon_id: edition.panopticon_id, state: 'archived').count
    end
  end

  test "edition can return latest status action of a specified request type" do
    edition = FactoryGirl.create(:guide_edition, :state => 'draft')
    user = User.create(:name => 'George')
    user.request_review edition, comment: "Requesting review"

    assert_equal edition.actions.size, 1
    assert edition.latest_status_action(Action::REQUEST_REVIEW).present?
  end

  test "a published edition can't be edited" do
    edition = FactoryGirl.create(:guide_edition, :state => 'published')
    edition.title = "My New Title"

    assert ! edition.save
    assert_equal ["Published editions can't be edited"], edition.errors[:base]
  end

  test "edition's publish history is recorded" do
    without_metadata_denormalisation(GuideEdition) do
      edition = FactoryGirl.create(:guide_edition, :state => 'ready')

      user = User.create :name => 'bob'
      user.publish edition, comment: "First publication"

      second_edition = edition.build_clone
      second_edition.update_attribute(:state, 'ready')
      second_edition.save!
      user.publish second_edition, comment: "Second publication"

      third_edition = second_edition.build_clone
      third_edition.update_attribute(:state, 'ready')
      third_edition.save!
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


 # TODO: has_draft? no longer exists. needs rewriting once this has been worked out
 # test 'a guide with all versions published should not have drafts' do
 #
 #   guide = unpublished_template_guide
 #   assert guide.has_draft?
 #   assert !guide.has_published?
 #   user = User.create :name => "Winston"
 #
 #    guide.editions.each do |e|
 #       e.state = 'ready' #force ready state so that we can publish
 #       user.publish e, { comment: "Publishing this" }
 #    end
 #
 #    assert !guide.has_draft?
 #    assert guide.has_published?
 #  end

  test "a new guide edition with multiple parts creates a full diff when published" do
    without_metadata_denormalisation(GuideEdition) do
      user = User.create :name => 'Roland'

      edition_one = GuideEdition.new(:name => "One", :slug => "one", :panopticon_id => 1, :title => "One")
      edition_one.parts.build :title => 'Part One', :body=>"Never gonna give you up", :slug => 'part-one'
      edition_one.parts.build :title => 'Part Two', :body=>"NYAN NYAN NYAN NYAN", :slug => 'part-two'
      edition_one.save!

      edition_one.state = :ready
      user.publish edition_one, comment: "First edition"

      edition_two = edition_one.build_clone
      edition_two.save!
      edition_two.parts.first.update_attribute :title, "Changed Title"
      edition_two.parts.first.update_attribute :body, "Never gonna let you down"

      edition_two.state = :ready
      user.publish edition_two, comment: "Second edition"

      publish_action = edition_two.actions.where(request_type: "publish").last

      assert_equal "{\"# Part One\" >> \"# Changed Title\"}\n\n{\"Never gonna give you up\" >> \"Never gonna let you down\"}\n\n# Part Two\n\nNYAN NYAN NYAN NYAN", publish_action.diff
    end
  end

  # TODO: has_draft? no longer exists. needs rewriting once this has been worked out
  # test 'a programme with all versions published should not have drafts' do
  #   programme = template_programme
  #
  #   assert !programme.has_draft?
  #   assert programme.has_published?
  # end
  #
  # test 'a programme with one published and one draft edition is marked as having drafts and having published' do
  #   programme = template_programme
  #   programme.build_edition("Two")
  #
  #   assert programme.has_draft?
  #   assert programme.has_published?
  # end

  test "user should not be able to review an edition they requested review for" do
    without_metadata_denormalisation(ProgrammeEdition) do
      user = User.create(:name => "Mary")

      edition = ProgrammeEdition.new(:name => "Childcare", :slug => "childcare", :panopticon_id => 1, :title => "Children")
      user.start_work(edition)
      assert edition.can_request_review?
      user.request_review(edition,{:comment => "Review this programme please."})
      assert ! user.request_amendments(edition, {:comment => "Well Done, but work harder"})
    end
  end

  test "a new programme edition with multiple parts creates a full diff when published" do
    without_metadata_denormalisation(ProgrammeEdition) do
      user = User.create :name => 'Mazz'

      edition_one = ProgrammeEdition.new(:name => "Childcare", :slug => "childcare", :panopticon_id => 1, :title => "Children")
      edition_one.parts.build :title => 'Part One', :body=>"Content for part one", :slug => 'part-one'
      edition_one.parts.build :title => 'Part Two', :body=>"Content for part two", :slug => 'part-two'
      edition_one.save!

      edition_one.state = :ready
      user.publish edition_one, comment: "First edition"

      edition_two = edition_one.build_clone
      edition_two.save!
      edition_two.parts.first.update_attribute :body, "Some other content"
      edition_two.state = :ready
      user.publish edition_two, comment: "Second edition"

      publish_action = edition_two.actions.where(request_type: "publish").last

      assert_equal "# Part One\n\n{\"Content for part one\" >> \"Some other content\"}\n\n# Part Two\n\nContent for part two", publish_action.diff
    end
  end

  test "a published publication with a draft edition is in progress" do
    dummy_answer = template_published_answer
    assert !dummy_answer.has_sibling_in_progress?

    edition = dummy_answer.build_clone
    edition.save

    assert dummy_answer.has_sibling_in_progress?
  end

  test "a draft edition cannot be published" do
    edition = FactoryGirl.create(:guide_edition, :state => 'draft')
    edition.start_work
    assert_false edition.can_publish?
  end

  test "a draft edition can be emergency published" do
    edition = FactoryGirl.create(:guide_edition, :state => 'draft')
    edition.start_work
    assert edition.can_emergency_publish?
  end


  # test denormalisation

  context "denormalising users" do

    should "denormalise an edition with an assigned user and action requesters" do
      @user1 = FactoryGirl.create(:user, :name => "Morwenna")
      @user2 = FactoryGirl.create(:user, :name => "John")
      @user3 = FactoryGirl.create(:user, :name => "Nick")

      edition = FactoryGirl.create(:guide_edition, :state => 'archived')

      edition = FactoryGirl.create(:guide_edition, :state => 'archived', :assigned_to_id => @user1.id)
      edition.actions.create :request_type => Action::CREATE, :requester => @user2
      edition.actions.create :request_type => Action::PUBLISH, :requester => @user3
      edition.actions.create :request_type => Action::ARCHIVE, :requester => @user1
      edition.save! and edition.reload

      assert_equal @user1.name, edition.assignee
      assert_equal @user2.name, edition.creator
      assert_equal @user3.name, edition.publisher
      assert_equal @user1.name, edition.archiver
    end

    should "denormalise an assignee's name when an edition is assigned" do
      @user1 = FactoryGirl.create(:user)
      @user2 = FactoryGirl.create(:user)

      edition = FactoryGirl.create(:guide_edition, :state => 'lined_up')
      @user1.assign edition, @user2

      assert_equal @user2, edition.assigned_to
      assert_equal @user2.name, edition.assignee
    end

    should "denormalise a creator's name when an edition is created" do
      @user = FactoryGirl.create(:user)

      edition = AnswerEdition.create_from_panopticon_data('2356', @user)

      assert_equal @user.name, edition.creator
    end

    should "denormalise a publishing user's name when an edition is published" do
      @user = FactoryGirl.create(:user)

      edition = FactoryGirl.create(:guide_edition, :state => 'ready')
      @user.publish edition, { }

      assert_equal @user.name, edition.publisher
    end

  end
end
