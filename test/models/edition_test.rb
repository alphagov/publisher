require "test_helper"

class Edition
  def update_in_search_index
  end
end

class EditionTest < ActiveSupport::TestCase
  def setup
    @artefact = FactoryGirl.create(:artefact)
  end

  def template_answer(version_number = 1)
    artefact = FactoryGirl.create(:artefact,
        kind: "answer",
        name: "Foo bar",
        owning_app: "publisher")

    AnswerEdition.create(state: "ready", slug: "childcare", panopticon_id: artefact.id,
      title: "Child care stuff", body: "Lots of info", version_number: version_number)
  end

  def template_published_answer(version_number = 1)
    answer = template_answer(version_number)
    answer.publish!
    answer.save!
    answer
  end

  def template_transaction
    artefact = FactoryGirl.create(:artefact)
    TransactionEdition.create(title: "One", introduction: "introduction",
      more_information: "more info", panopticon_id: @artefact.id, slug: "childcare")
  end

  def template_unpublished_answer(version_number = 1)
    template_answer(version_number)
  end

  def draft_second_edition_from(published_edition)
    published_edition.build_clone(AnswerEdition).tap { |edition|
      edition.body = "Test Body 2"
      edition.save
      edition.reload
    }
  end

  test "it must have a title" do
    a = LocalTransactionEdition.new
    refute a.valid?
    assert a.errors[:title].any?
  end

  test "it is not in beta by default" do
    refute FactoryGirl.build(:guide_edition).in_beta?
  end

  test "it can be in beta" do
    assert FactoryGirl.build(:guide_edition, in_beta: true).in_beta?
  end

  test "it should give a friendly (legacy supporting) description of its format" do
    a = LocalTransactionEdition.new
    assert_equal "LocalTransaction", a.format
  end

  test "it should be able to find its siblings" do
    artefact2 = FactoryGirl.create(:artefact)
    g1 = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, version_number: 1)
    g2 = FactoryGirl.create(:guide_edition, panopticon_id: artefact2.id, version_number: 1)
    g3 = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, version_number: 2)
    assert_equal [], g2.siblings.to_a
    assert_equal [g3], g1.siblings.to_a
  end

  test "it should be able to find its previous siblings" do
    artefact2 = FactoryGirl.create(:artefact)
    g1 = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, version_number: 1)
    g2 = FactoryGirl.create(:guide_edition, panopticon_id: artefact2.id, version_number: 1)
    g3 = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, version_number: 2)

    assert_equal [], g1.previous_siblings.to_a
    assert_equal [g1], g3.previous_siblings.to_a
  end

  test "subsequent and previous siblings are in order" do
    g4 = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, version_number: 4)
    g2 = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, version_number: 2)
    g1 = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, version_number: 1)
    g3 = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, version_number: 3)

    assert_equal [g2, g3, g4], g1.subsequent_siblings.to_a
    assert_equal [g1, g2, g3], g4.previous_siblings.to_a
  end

  test "A programme should have default parts" do
    programme = FactoryGirl.create(:programme_edition, panopticon_id: @artefact.id)
    assert_equal programme.parts.count, ProgrammeEdition::DEFAULT_PARTS.length
  end

  context "link validation" do
    should "not be done when the edition is created" do
      assert_difference 'AnswerEdition.count', 1 do
        FactoryGirl.create(:answer_edition, body: 'abc [foobar](http://foobar.com "hover")')
      end
    end

    should "be done when an existing edition is updated" do
      edition = FactoryGirl.create(:answer_edition, body: 'abc [foobar](http://foobar.com "hover")')

      edition.body += "some update"

      refute edition.valid?
      assert_includes edition.errors.full_messages, %q<Body ["Don't include hover text in links. Delete the text in quotation marks eg \\"This appears when you hover over the link.\\""]>
    end

    should "allow archiving an edition with invalid links" do
      edition = FactoryGirl.create(:answer_edition, state: 'published', body: 'abc [foobar](http://foobar.com "hover")')

      assert_difference 'AnswerEdition.archived.count', 1 do
        edition.archive!
      end
    end
  end

  context "change note" do
    should "be a minor change by default" do
      refute AnswerEdition.new.major_change
    end
    should "not be valid for major changes with a blank change note" do
      edition = AnswerEdition.new(major_change: true, change_note: "")
      refute edition.valid?
      assert edition.errors.has_key?(:change_note)
    end
    should "be valid for major changes with a change note" do
      edition = AnswerEdition.new(title: "Edition", version_number: 1, panopticon_id: 123, major_change: true, change_note: "Changed")
      assert edition.valid?
    end
    should "be valid when blank for minor changes" do
      edition = AnswerEdition.new(title: "Edition", version_number: 1, panopticon_id: 123, change_note: "")
      assert edition.valid?
    end
    should "be valid when populated for minor changes" do
      edition = AnswerEdition.new(title: "Edition", version_number: 1, panopticon_id: 123, change_note: "Changed")
      assert edition.valid?
    end
  end

  test "reviewer cannot be the assignee" do
    user = FactoryGirl.create(:user)
    edition = AnswerEdition.new(title: "Edition", version_number: 1, panopticon_id: 123,
                          state: "in_review", review_requested_at: Time.zone.now, assigned_to: user)
    edition.reviewer = user.name
    refute edition.valid?
    assert edition.errors.has_key?(:reviewer)
  end

  test "it should build a clone" do
    edition = FactoryGirl.create(:guide_edition,
                                  state: "published",
                                  panopticon_id: @artefact.id,
                                  version_number: 1,
                                  overview: "I am a test overview")
    clone_edition = edition.build_clone
    assert_equal "I am a test overview", clone_edition.overview
    assert_equal 2, clone_edition.version_number
  end

  test "cloning can only occur from a published edition" do
    edition = FactoryGirl.create(:guide_edition,
                                  panopticon_id: @artefact.id,
                                  version_number: 1)
    assert_raise(RuntimeError) do
      edition.build_clone
    end
  end

  test "cloning can only occur from a published edition with no subsequent in progress siblings" do
    edition = FactoryGirl.create(:guide_edition,
                                  panopticon_id: @artefact.id,
                                  state: "published",
                                  version_number: 1)

    FactoryGirl.create(:guide_edition,
                        panopticon_id: @artefact.id,
                        state: "draft",
                        version_number: 2)

    assert_raise(RuntimeError) do
      edition.build_clone
    end
  end

  test "cloning from an earlier edition should give you a safe version number" do
    edition = FactoryGirl.create(:guide_edition,
                                  state: "published",
                                  panopticon_id: @artefact.id,
                                  version_number: 1)
    edition_two = FactoryGirl.create(:guide_edition,
                                  state: "published",
                                  panopticon_id: @artefact.id,
                                  version_number: 2)

    clone1 = edition.build_clone
    assert_equal 3, clone1.version_number
  end

# test cloning into different edition types
  Edition.subclasses.permutation(2).each do |source_class, destination_class|
    test "it should be possible to clone from a #{source_class} to a #{destination_class}" do
      # Note that the new edition won't necessarily be valid - for example the
      # new type might have required fields that the old just doesn't have.
      # This is OK because when Publisher saves the clone, it already skips
      # validations. The user will then be required to populate those values
      # before they save the edition again.
      source_edition = FactoryGirl.create(:edition, _type: source_class.to_s, state: "published")

      assert_nothing_raised do
        new_edition = source_edition.build_clone(destination_class)
      end
    end
  end

  test "Cloning from GuideEdition into AnswerEdition" do
    edition = FactoryGirl.create(
        :guide_edition,
        state: "published",
        panopticon_id: @artefact.id,
        version_number: 1,
        overview: "I am a test overview",
        video_url: "http://www.youtube.com/watch?v=dQw4w9WgXcQ"
    )
    new_edition = edition.build_clone AnswerEdition

    assert_equal AnswerEdition, new_edition.class
    assert_equal 2, new_edition.version_number
    assert_equal @artefact.id.to_s, new_edition.panopticon_id
    assert_equal "draft", new_edition.state
    assert_equal "I am a test overview", new_edition.overview
    assert_equal edition.whole_body, new_edition.whole_body
  end

  test "Cloning from LicenceEdition into AnswerEdition" do
    edition = FactoryGirl.create(
      :licence_edition,
      state: "published",
      panopticon_id: @artefact.id,
      version_number: 1,
      licence_overview: "I am a test overview",
      licence_identifier: "Test identifier",
      licence_short_description: "I am a test short description",
      will_continue_on: "test will continue on",
      continuation_link: "https://github.com/alphagov/"
    )
    new_edition = edition.build_clone AnswerEdition

    assert_equal AnswerEdition, new_edition.class
    assert_equal 2, new_edition.version_number
    assert_equal @artefact.id.to_s, new_edition.panopticon_id
    assert_equal "draft", new_edition.state
    assert_match /#{edition.licence_overview}/, new_edition.body
    assert_match /#{edition.licence_short_description}/, new_edition.body
    assert_equal edition.whole_body, new_edition.body
  end

  test "Cloning from TransactionEdition into AnswerEdition" do
    edition = FactoryGirl.create(
        :transaction_edition,
        state: "published",
        panopticon_id: @artefact.id,
        version_number: 1,
        overview: "I am a test overview",
        more_information: "More information",
        alternate_methods: "Alternate methods"
    )
    new_edition = edition.build_clone AnswerEdition

    assert_equal AnswerEdition, new_edition.class
    assert_equal 2, new_edition.version_number
    assert_equal @artefact.id.to_s, new_edition.panopticon_id
    assert_equal "draft", new_edition.state
    assert_equal "I am a test overview", new_edition.overview
    assert_equal edition.whole_body, new_edition.whole_body
  end

  test "Cloning from SimpleSmartAnswerEdition into AnswerEdition" do
    edition = FactoryGirl.create(
        :simple_smart_answer_edition,
        state: "published",
        panopticon_id: @artefact.id,
        version_number: 1,
        overview: "I am a test overview",
    )
    new_edition = edition.build_clone AnswerEdition

    assert_equal AnswerEdition, new_edition.class
    assert_equal 2, new_edition.version_number
    assert_equal @artefact.id.to_s, new_edition.panopticon_id
    assert_equal "draft", new_edition.state
    assert_equal "I am a test overview", new_edition.overview
    assert_equal edition.whole_body, new_edition.whole_body
  end

  test "Cloning from AnswerEdition into TransactionEdition" do
    edition = FactoryGirl.create(
        :answer_edition,
        state: "published",
        panopticon_id: @artefact.id,
        version_number: 1,
        overview: "I am a test overview",
        body: "Test body"
    )
    new_edition = edition.build_clone TransactionEdition

    assert_equal TransactionEdition, new_edition.class
    assert_equal 2, new_edition.version_number
    assert_equal @artefact.id.to_s, new_edition.panopticon_id
    assert_equal "draft", new_edition.state
    assert_equal "I am a test overview", new_edition.overview
    assert_equal "Test body", new_edition.more_information
  end

  test "Cloning from AnswerEdition into SimpleSmartAnswerEdition" do
    edition = FactoryGirl.create(
      :answer_edition,
      state: "published",
      panopticon_id: @artefact.id,
      version_number: 1,
      overview: "I am a test overview",
      body: "Test body"
    )
    new_edition = edition.build_clone SimpleSmartAnswerEdition

    assert_equal SimpleSmartAnswerEdition, new_edition.class
    assert_equal 2, new_edition.version_number
    assert_equal @artefact.id.to_s, new_edition.panopticon_id
    assert_equal "draft", new_edition.state
    assert_equal "I am a test overview", new_edition.overview
    assert_equal "Test body", new_edition.body
  end

  test "Cloning from GuideEdition into TransactionEdition" do
    edition = FactoryGirl.create(
        :guide_edition,
        state: "published",
        panopticon_id: @artefact.id,
        version_number: 1,
        overview: "I am a test overview",
        video_url: "http://www.youtube.com/watch?v=dQw4w9WgXcQ"
    )
    new_edition = edition.build_clone TransactionEdition

    assert_equal TransactionEdition, new_edition.class
    assert_equal 2, new_edition.version_number
    assert_equal @artefact.id.to_s, new_edition.panopticon_id
    assert_equal "draft", new_edition.state
    assert_equal "I am a test overview", new_edition.overview
    assert_equal edition.whole_body, new_edition.more_information
  end

  test "Cloning from AnswerEdition into GuideEdition" do
    edition = FactoryGirl.create(
        :answer_edition,
        state: "published",
        panopticon_id: @artefact.id,
        version_number: 1,
        overview: "I am a test overview",
    )
    new_edition = edition.build_clone GuideEdition

    assert_equal GuideEdition, new_edition.class
    assert_equal 2, new_edition.version_number
    assert_equal @artefact.id.to_s, new_edition.panopticon_id
    assert_equal "draft", new_edition.state
    assert_equal "I am a test overview", new_edition.overview
  end

  test "knows the common fields of two edition subclasses" do
    to_copy = Set.new([:introduction, :need_to_know, :more_information])
    result = Set.new(TransactionEdition.new.fields_to_copy(PlaceEdition))
    assert to_copy.proper_subset?(result)
  end

  # Mongoid 2.x marks array fields as dirty whenever they are accessed.
  # See https://github.com/mongoid/mongoid/issues/2311
  # This behaviour has been patched in lib/mongoid/monkey_patches.rb
  # in order to prevent workflow validation failures for editions
  # with array fields.
  #
  test "editions with array fields should accurately track changes" do
    bs = FactoryGirl.create(:business_support_edition, sectors: [])
    assert_empty bs.changes
    bs.sectors
    assert_empty bs.changes
    bs.sectors << 'manufacturing'
    assert_equal ['sectors'], bs.changes.keys
  end

  test "edition finder should return the published edition when given an empty edition parameter" do
    dummy_publication = template_published_answer
    second_publication = template_unpublished_answer(2)

    assert dummy_publication.published?
    assert_equal dummy_publication, Edition.find_and_identify("childcare", "")
  end

  test "edition finder should return the latest edition when asked" do
    dummy_publication = template_published_answer
    second_publication = template_unpublished_answer(2)

    assert_equal 2, Edition.where(slug: dummy_publication.slug).count
    found_edition = Edition.find_and_identify("childcare", "latest")
    assert_equal second_publication.version_number, found_edition.version_number
  end

  test "a publication should not have a video" do
    dummy_publication = template_published_answer
    assert !dummy_publication.has_video?
  end

  test "should create a publication based on data imported from panopticon" do
    artefact = FactoryGirl.create(:artefact,
        slug: "foo-bar",
        kind: "answer",
        name: "Foo bar",
        owning_app: "publisher",
    )
    artefact.save!

    a = Artefact.find(artefact.id)
    user = User.create

    publication = Edition.find_or_create_from_panopticon_data(artefact.id, user)

    assert_kind_of AnswerEdition, publication
    assert_equal artefact.name, publication.title
    assert_equal artefact.id.to_s, publication.panopticon_id.to_s
  end

  test "should not change edition metadata if archived" do
    artefact = FactoryGirl.create(:artefact,
        slug: "foo-bar",
        kind: "answer",
        name: "Foo bar",
        owning_app: "publisher",
    )

    guide = FactoryGirl.create(:guide_edition,
      panopticon_id: artefact.id,
      title: "Original title",
      slug: "original-title",
      state: "archived"
    )
    artefact.slug = "new-slug"
    artefact.save

    assert_not_equal "new-slug", guide.reload.slug
  end

  test "should scope publications by assignee" do
    stub_request(:get, %r{http://panopticon\.test\.gov\.uk/artefacts/.*\.js}).
        to_return(status: 200, body: "{}", headers: {})

    a, b = 2.times.map { FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id) }

    alice, bob, charlie = %w[ alice bob charlie ].map { |s|
      FactoryGirl.create(:user, name: s)
    }
    alice.assign(a, bob)
    alice.assign(a, charlie)
    alice.assign(b, bob)

    assert_equal [b], Edition.assigned_to(bob).to_a
  end

  test "cannot delete a publication that has been published" do
    dummy_answer = template_published_answer
    loaded_answer = AnswerEdition.where(slug: "childcare").first

    assert_equal loaded_answer, dummy_answer
    assert ! dummy_answer.can_destroy?
    assert_raise (Workflow::CannotDeletePublishedPublication) do
      dummy_answer.destroy
    end
  end

  test "cannot delete a published publication with a new draft edition" do
    dummy_answer = template_published_answer

    new_edition = dummy_answer.build_clone
    new_edition.body = "Two"
    dummy_answer.save

    assert_raise (Edition::CannotDeletePublishedPublication) do
      dummy_answer.destroy
    end
  end

  test "can delete a publication that has not been published" do
    dummy_answer = template_unpublished_answer
    dummy_answer.destroy

    loaded_answer = AnswerEdition.where(slug: dummy_answer.slug).first
    assert_nil loaded_answer
  end

  test "deleting a newer draft of a published edition removes sibling information" do
    user1 = FactoryGirl.create(:user)
    edition = AnswerEdition.find_or_create_from_panopticon_data(@artefact.id, user1)
    edition.update_attribute(:state, "published")
    second_edition = edition.build_clone
    second_edition.save!
    edition.reload

    assert edition.sibling_in_progress

    second_edition.destroy
    edition.reload

    assert_nil edition.sibling_in_progress
  end

  test "the latest edition should remove sibling_in_progress details if it is present" do
    user1 = FactoryGirl.create(:user)
    edition = AnswerEdition.find_or_create_from_panopticon_data(@artefact.id, user1)
    edition.update_attribute(:state, "published")

    # simulate a document having a newer edition destroyed (previous behaviour).
    edition.sibling_in_progress = 2
    edition.save(validate: false)

    assert edition.can_create_new_edition?
  end

  test "should also delete associated artefact" do
    user1 = FactoryGirl.create(:user)
    edition = AnswerEdition.find_or_create_from_panopticon_data(@artefact.id, user1)

    assert_difference "Artefact.count", -1 do
      edition.destroy
    end
  end

  test "should not delete associated artefact if there are other editions of this publication" do
    user1 = FactoryGirl.create(:user)
    edition = AnswerEdition.find_or_create_from_panopticon_data(@artefact.id, user1)
    edition.update_attribute(:state, "published")

    edition.reload
    second_edition = edition.build_clone
    second_edition.save!

    assert_no_difference "Artefact.count" do
      second_edition.destroy
    end
  end

  test "should scope publications assigned to nobody" do
    stub_request(:get, %r{http://panopticon\.test\.gov\.uk/artefacts/.*\.js}).
        to_return(status: 200, body: "{}", headers: {})

    a, b = 2.times.map { |i| FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id) }

    alice, bob, charlie = %w[ alice bob charlie ].map { |s|
      FactoryGirl.create(:user, name: s)
    }

    alice.assign(a, bob)
    a.reload
    assert_equal bob, a.assigned_to

    alice.assign(a, charlie)
    a.reload
    assert_equal charlie, a.assigned_to

    assert_equal 2, Edition.count
    assert_equal [b], Edition.assigned_to(nil).to_a
    assert_equal [], Edition.assigned_to(bob).to_a
    assert_equal [a], Edition.assigned_to(charlie).to_a
  end

  test "given multiple editions, can return the most recent published edition" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, slug: "hedgehog-topiary", state: "published")

    second_edition = edition.build_clone
    edition.update_attribute(:state, "archived")
    second_edition.update_attribute(:state, "published")

    third_edition = second_edition.build_clone
    third_edition.update_attribute(:state, "draft")

    assert_equal edition.published_edition, second_edition
  end

  test "editions, by default, return their title for use in the admin-interface lists of publications" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    assert_equal edition.title, edition.admin_list_title
  end

  test "editions can have notes stored for the history tab" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    user = User.new
    assert edition.new_action(user, "note", comment: "Something important")
  end

  test "status should not be affected by notes" do
    user = User.create(name: "bob")
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    edition.new_action(user, Action::APPROVE_REVIEW)
    edition.new_action(user, Action::NOTE, comment: "Something important")

    assert_equal Action::APPROVE_REVIEW, edition.latest_status_action.request_type
  end

  test "should have no assignee by default" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    assert_nil edition.assigned_to
  end

  test "should be assigned to the last assigned recipient" do
    alice = FactoryGirl.create(:user, name: "alice")
    bob = FactoryGirl.create(:user, name: "bob")
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    alice.assign(edition, bob)
    assert_equal bob, edition.assigned_to
  end

  test "new edition should have an incremented version number" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "published")
    new_edition = edition.build_clone
    assert_equal edition.version_number + 1, new_edition.version_number
  end

  test "new edition should have an empty list of actions" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "published")
    new_edition = edition.build_clone
    assert_equal [], new_edition.actions
  end

  test "new editions should have the same text when created" do
    edition = FactoryGirl.create(:guide_edition_with_two_parts, panopticon_id: @artefact.id, state: "published")
    new_edition = edition.build_clone
    original_text = edition.parts.map {|p| p.body }.join(" ")
    new_text = new_edition.parts.map {|p| p.body }.join(" ")
    assert_equal original_text, new_text
  end

  test "changing text in a new edition should not change text in old edition" do
    edition = FactoryGirl.create(:guide_edition_with_two_parts, panopticon_id: @artefact.id, state: "published")
    new_edition = edition.build_clone
    new_edition.parts.first.body = "Some other version text"
    original_text = edition.parts.map {|p| p.body }.join(" ")
    new_text = new_edition.parts.map {|p| p.body }.join(" ")
    assert_not_equal original_text, new_text
  end

  test "a new guide has no published edition" do
    guide = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    assert_nil GuideEdition.where(state: "published", panopticon_id: guide.panopticon_id).first
  end

  test "an edition of a guide can be published" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    edition.publish
    assert_not_nil GuideEdition.where(state: "published", panopticon_id: edition.panopticon_id).first
  end

  test "should archive older editions, even if there are validation errors, when a new edition is published" do
    edition = FactoryGirl.create(:guide_edition_with_two_parts, panopticon_id: @artefact.id, state: "ready")

    user = User.create name: "bob"
    publish(user, edition, "First publication")

    second_edition = edition.build_clone
    second_edition.state = "ready"
    second_edition.save!

    publish(user, second_edition, "Second publication")

    # simulate link validation errors in published edition
    second_edition.parts.first.update_attribute(:body, "[register your vehicle](registering-an-imported-vehicle)")

    third_edition = second_edition.build_clone
    # fix link validation error in cloned edition by appending a '/' to the relative url
    third_edition.parts.first.body = "[register your vehicle](/registering-an-imported-vehicle)"
    third_edition.state = "ready"
    third_edition.save!

    publish(user, third_edition, "Third publication")

    edition.reload
    assert edition.archived?

    second_edition.reload
    assert second_edition.archived?

    assert_equal 2, GuideEdition.where(panopticon_id: edition.panopticon_id, state: "archived").count
  end

  test "when an edition is published, publish_at is cleared" do
    user = FactoryGirl.create(:user)
    edition = FactoryGirl.create(:edition, :scheduled_for_publishing)

    publish(user, edition, "First publication")

    assert_nil edition.reload.publish_at
  end

  test "edition can return latest status action of a specified request type" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "draft")
    user = User.create(name: "George")
    request_review(user, edition)

    assert_equal edition.actions.size, 1
    assert edition.latest_status_action(Action::REQUEST_REVIEW).present?
  end

  test "a published edition can't be edited" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "published")
    edition.title = "My New Title"

    assert ! edition.save
    assert_equal ["Published editions can't be edited"], edition.errors[:base]
  end

  test "edition's publish history is recorded" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")

    user = User.create name: "bob"
    publish(user, edition, "First publication")

    second_edition = edition.build_clone
    second_edition.update_attribute(:state, "ready")
    second_edition.save!
    publish(user, second_edition, "Second publication")

    third_edition = second_edition.build_clone
    third_edition.update_attribute(:state, "ready")
    third_edition.save!
    publish(user, third_edition, "Third publication")

    edition.reload
    assert edition.actions.where("request_type" => "publish")

    second_edition.reload
    assert second_edition.actions.where("request_type" => "publish")

    third_edition.reload
    assert third_edition.actions.where("request_type" => "publish")
    assert third_edition.published?
  end


 test "a series with all editions published should not have siblings in progress" do
   edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")

   user = User.create name: "bob"
   publish(user, edition, "First publication")

   new_edition = edition.build_clone
   new_edition.state = "ready"
   new_edition.save!
   publish(user, new_edition, "Second publication")

   edition = edition.reload

   assert_nil edition.sibling_in_progress
  end

  test "a series with one published and one draft edition should have a sibling in progress" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    edition.save!

    user = User.create name: "bob"
    publish(user, edition, "First publication")

    new_edition = edition.build_clone
    new_edition.save!

    edition = edition.reload

    assert_not_nil edition.sibling_in_progress
    assert_equal new_edition.version_number, edition.sibling_in_progress
  end

  test "a part's slug must be of the correct format" do
    edition_one = GuideEdition.new(title: "One", slug: "one", panopticon_id: @artefact.id)
    edition_one.parts.build title: "Part One", body:"Never gonna give you up", slug: "part-One-1"
    edition_one.save!

    edition_one.parts[0].slug = "part one"
    assert_raise (Mongoid::Errors::Validations) do
      edition_one.save!
    end
  end

  test "parts can be sorted by the order field using a scope" do
    edition = GuideEdition.new(title: "One", slug: "one", panopticon_id: @artefact.id)
    edition.parts.build title: "Biscuits", body:"Never gonna give you up", slug: "biscuits", order: 2
    edition.parts.build title: "Cookies", body:"NYAN NYAN NYAN NYAN", slug: "cookies", order: 1
    edition.save!
    edition.reload

    assert_equal "Cookies", edition.parts.in_order.first.title
    assert_equal "Biscuits", edition.parts.in_order.last.title
  end

  test "user should not be able to review an edition they requested review for" do
    user = User.create(name: "Mary")

    edition = ProgrammeEdition.create(title: "Childcare", slug: "childcare", panopticon_id: @artefact.id)
    assert edition.can_request_review?
    request_review(user, edition)
    refute request_amendments(user, edition)
  end

  test "a published publication with a draft edition is in progress" do
    dummy_answer = template_published_answer
    assert !dummy_answer.has_sibling_in_progress?

    edition = dummy_answer.build_clone
    edition.save

    dummy_answer.reload
    assert dummy_answer.has_sibling_in_progress?
  end

  test "a draft edition cannot be published" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "draft")
    refute edition.can_publish?
  end

  # test denormalisation

  test "should denormalise an edition with an assigned user and action requesters" do
    user1 = FactoryGirl.create(:user, name: "Morwenna")
    user2 = FactoryGirl.create(:user, name: "John")
    user3 = FactoryGirl.create(:user, name: "Nick")

    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "archived")

    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "archived", assigned_to_id: user1.id)
    edition.actions.create request_type: Action::CREATE, requester: user2
    edition.actions.create request_type: Action::PUBLISH, requester: user3
    edition.actions.create request_type: Action::ARCHIVE, requester: user1
    edition.save! and edition.reload

    assert_equal user1.name, edition.assignee
    assert_equal user2.name, edition.creator
    assert_equal user3.name, edition.publisher
    assert_equal user1.name, edition.archiver
  end

  test "should denormalise an assignee's name when an edition is assigned" do
    user1 = FactoryGirl.create(:user)
    user2 = FactoryGirl.create(:user)

    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "draft")
    user1.assign edition, user2

    assert_equal user2, edition.assigned_to
    assert_equal user2.name, edition.assignee
  end

  test "should denormalise a creator's name when an edition is created" do
    user = FactoryGirl.create(:user)
    artefact = FactoryGirl.create(:artefact,
        slug: "foo-bar",
        kind: "answer",
        name: "Foo bar",
        owning_app: "publisher",
    )

    edition = AnswerEdition.find_or_create_from_panopticon_data(artefact.id, user)

    assert_equal user.name, edition.creator
  end

  test "should denormalise a publishing user's name when an edition is published" do
    user = FactoryGirl.create(:user)

    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    publish(user, edition, "First publication")

    assert_equal user.name, edition.publisher
  end

  test "should set siblings in progress to nil for new editions" do
    user = FactoryGirl.create(:user)
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    published_edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "published")
    assert_equal 1, edition.version_number
    assert_nil edition.sibling_in_progress
  end

  test "should update previous editions when new edition is added" do
    user = FactoryGirl.create(:user)
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "archived")
    published_edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "published")
    new_edition = published_edition.build_clone
    new_edition.save!
    published_edition.reload

    assert_equal 3, new_edition.version_number
    assert_equal 3, published_edition.sibling_in_progress
  end

  test "should update previous editions when new edition is published" do
    user = FactoryGirl.create(:user)
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "archived")
    published_edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "published")

    new_edition = published_edition.build_clone
    new_edition.save!
    new_edition.update_attribute(:state, "ready")
    publish(user, new_edition, "First publication")

    assert_equal 3, new_edition.version_number
    assert_nil new_edition.sibling_in_progress
    assert_nil published_edition.reload.sibling_in_progress
  end

  test "all subclasses should provide a working whole_body method for diffing" do
    Edition.subclasses.each do |klass|
      assert klass.instance_methods.include?(:whole_body), "#{klass} doesn't provide a whole_body"
      assert_nothing_raised do
        klass.new.whole_body
      end
    end
  end

  test "should convert a GuideEdition to an AnswerEdition" do
    guide_edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "published")
    answer_edition = guide_edition.build_clone(AnswerEdition)

    assert_equal guide_edition.whole_body, answer_edition.whole_body
  end

  test "should convert an AnswerEdition to a GuideEdition" do
    answer_edition = template_published_answer
    guide_edition = answer_edition.build_clone(GuideEdition)

    expected = "# Part One\n\n" + answer_edition.whole_body

    assert_equal expected, guide_edition.whole_body
  end

  test "should not allow any changes to an edition with an archived artefact" do
    artefact = FactoryGirl.create(:artefact)
    guide_edition = FactoryGirl.create(:guide_edition, state: 'draft', panopticon_id: artefact.id)
    artefact.state = 'archived'
    artefact.save

    assert_raise(RuntimeError) do
      guide_edition.title = "Error this"
      guide_edition.save!
    end
  end

  test "should return the artefact" do
    assert_equal "Foo bar", template_published_answer.artefact.name
  end

  context "validating version_number" do
    should "be required" do
      ed = FactoryGirl.build(:edition, :panopticon_id => @artefact.id)
      ed.version_number = nil
      assert !ed.valid?, "Expected edition not to be valid with no version_number"
    end

    should "be unique" do
      ed1 = FactoryGirl.create(:edition, :panopticon_id => @artefact.id)
      ed2 = FactoryGirl.build(:edition, :panopticon_id => @artefact.id)
      ed2.version_number = ed1.version_number

      assert !ed2.valid?, "Expected edition not to be valid with conflicting version_number"
    end

    should "allow editions belonging to different artefacts to have matching version_numbers" do
      ed1 = FactoryGirl.create(:edition, :panopticon_id => @artefact.id)
      ed2 = FactoryGirl.build(:edition, :panopticon_id => FactoryGirl.create(:artefact).id)
      ed2.version_number = ed1.version_number

      assert ed2.valid?, "Expected edition to be valid"
    end

    should "have a database-level constraint on the uniqueness" do
      ed1 = FactoryGirl.create(:edition, :panopticon_id => @artefact.id)
      ed2 = FactoryGirl.build(:edition, :panopticon_id => @artefact.id)
      ed2.version_number = ed1.version_number

      assert_raises Mongo::Error::OperationFailure do
        ed2.save! validate: false
      end
    end
  end

  context "indexable_content" do
    context "editions with a 'body'" do
      should "include the body with markup removed" do
        edition = FactoryGirl.create(:answer_edition, body: "## Title", panopticon_id: FactoryGirl.create(:artefact).id)
        assert_equal "Title", edition.indexable_content
      end
    end

    context "for a single part thing" do
      should "have an empty string for an edition with no body" do
        edition = FactoryGirl.create(:guide_edition, :state => 'ready', :title => 'one part thing', panopticon_id: FactoryGirl.create(:artefact).id)
        edition.publish
        assert_equal "", edition.indexable_content
      end
    end

    context "for a multi part thing" do
      should "have the normalised content of all parts" do
        edition = FactoryGirl.create(:guide_edition_with_two_parts, :state => 'ready', panopticon_id: FactoryGirl.create(:artefact).id)
        edition.publish
        assert_equal "PART ! This is some version text. PART !! This is some more version text.", edition.indexable_content
      end
    end

    context "indexable_content would contain govspeak" do
      should "convert it to plaintext" do
        edition = FactoryGirl.create(:guide_edition_with_two_govspeak_parts, :state => 'ready', panopticon_id: FactoryGirl.create(:artefact).id)
        edition.publish

        expected = "Some Part Title! This is some version text. Another Part Title This is link text."
        assert_equal expected, edition.indexable_content
      end
    end
  end

  context "#latest_major_update" do
    should 'return the most recent published edition with a major change' do
      edition1 = FactoryGirl.create(:answer_edition, major_change: true,
                                                     change_note: 'published',
                                                     state: 'published',
                                                     version_number: 1)
      edition2 = edition1.build_clone

      edition2.update_attributes!(major_change: true, change_note: 'changed', state: 'published')
      edition1.update_attributes!(state: 'archived')

      edition3 = edition2.build_clone

      assert_equal edition2.id, edition3.latest_major_update.id
    end
  end

  context "#latest_change_note" do
    should 'return the change note of the latest major update' do
      edition1 = FactoryGirl.create(:answer_edition, major_change: true,
                                                     change_note: 'a change note',
                                                     state: 'published')
      edition2 = edition1.build_clone

      assert_equal 'a change note', edition2.latest_change_note
    end

    should 'return nil if there is no major update in the edition series' do
      edition1 = FactoryGirl.create(:answer_edition, major_change: false,
                                                     state: 'published')
      assert_nil edition1.latest_change_note
    end
  end

  context '#public_updated_at' do
    should 'return the updated_at timestamp of the latest major update' do
      edition1 = FactoryGirl.create(:answer_edition, major_change: true,
                                                     change_note: 'a change note',
                                                     updated_at: 1.minute.ago,
                                                     state: 'published')
      edition2 = edition1.build_clone

      assert_in_delta edition1.updated_at, edition2.public_updated_at, 1.second
    end

    should 'return the timestamp of the first published edition when there are no major updates' do
      edition1 = FactoryGirl.create(:answer_edition, major_change: false,
                                                     updated_at: 2.minute.ago,
                                                     state: 'published')
      edition2 = edition1.build_clone
      Timecop.freeze(1.minute.ago) do
        #added to allow significant amount of time between edition updated_at values
        edition2.update_attributes!(state: 'published', major_change: false)
      end
      edition1.update_attributes!(state: 'archived', major_change: false)

      assert_in_delta edition1.updated_at, edition2.public_updated_at, 1.second
      assert_not_in_delta edition2.updated_at, edition2.public_updated_at, 1.second
    end

    should 'return nil if there are no major updates and no published editions' do
      edition1 = FactoryGirl.create(:answer_edition, major_change: false,
                                                     updated_at: 1.minute.ago,
                                                     state: 'draft')

      assert_nil edition1.public_updated_at
    end
  end

  context '#has_ever_been_published?' do
    should 'return true if any edition has a published state' do
      edition1 = FactoryGirl.create(:answer_edition, major_change: false,
        updated_at: 2.minute.ago,
        state: 'published')
      edition2 = edition1.build_clone
      edition2.update_attributes!(state: 'archived', major_change: false)
      edition4 = FactoryGirl.create(:answer_edition, major_change: false,
        updated_at: 2.minute.ago,
        state: 'draft')

      assert_equal true, edition1.has_ever_been_published?
      assert_equal true, edition2.has_ever_been_published?
      assert_equal false, edition4.has_ever_been_published?
    end
  end

  context '#first_edition_of_published' do
    should 'return the first edition of a series that has at least one edition state published' do
      edition1 = FactoryGirl.create(:answer_edition, major_change: false,
        updated_at: 2.minute.ago,
        state: 'published')
      edition2 = edition1.build_clone
      edition1.update_attributes!(state: 'archived', major_change: false)
      edition2.update_attributes!(state: 'published', major_change: false)
      edition3 = edition2.build_clone
      edition3.update_attributes!(state: 'archived', major_change: false)

      assert_equal edition1, edition1.first_edition_of_published
      assert_equal edition1, edition2.first_edition_of_published
      assert_equal edition1, edition3.first_edition_of_published
    end
  end
end
