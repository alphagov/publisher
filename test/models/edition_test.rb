require "test_helper"

class EditionTest < ActiveSupport::TestCase
  def setup
    @artefact = FactoryBot.create(:artefact)
    lgsl_code = 800
    FactoryBot.create(
      :local_service,
      lgsl_code:,
    )
  end

  def template_answer(version_number = 1)
    artefact = FactoryBot.create(
      :artefact,
      kind: "answer",
      name: "Foo bar",
      owning_app: "publisher",
    )

    FactoryBot.create(:answer_edition,
                      state: "ready",
                      slug: "childcare",
                      panopticon_id: artefact.id,
                      title: "Child care stuff",
                      body: "Lots of info",
                      version_number:)
  end

  def template_published_answer(version_number = 1)
    answer = template_answer(version_number)
    answer.publish!
    answer.save!
    answer
  end

  def template_transaction
    TransactionEdition.create(
      title: "One",
      introduction: "introduction",
      more_information: "more info",
      panopticon_id: @artefact.id,
      slug: "childcare",
    )
  end

  def template_unpublished_answer(version_number = 1)
    template_answer(version_number)
  end

  def draft_second_edition_from(published_edition)
    published_edition.build_clone(AnswerEdition).tap do |edition|
      edition.body = "Test Body 2"
      edition.save!
      edition.reload
    end
  end

  test "it must have a title" do
    local_transaction = FactoryBot.build(:local_transaction_edition, panopticon_id: @artefact.id, lgsl_code: 800)
    local_transaction.title = nil

    assert_not local_transaction.valid?
    assert local_transaction.errors[:title].any?
  end

  test "it is not in beta by default" do
    assert_not FactoryBot.build(:guide_edition).in_beta?
  end

  test "it can be in beta" do
    assert FactoryBot.build(:guide_edition, in_beta: true).in_beta?
  end

  test "it should give a friendly (legacy supporting) description of its format" do
    service = LocalService.create!(lgsl_code: 1, providing_tier: %w[county unitary])
    local_transaction = FactoryBot.create(:local_transaction_edition, panopticon_id: @artefact.id, lgil_code: 1, lgsl_code: service.lgsl_code)
    assert_equal "LocalTransaction", local_transaction.format
  end

  test "it should be able to find its siblings" do
    artefact2 = FactoryBot.create(:artefact)
    g1 = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, version_number: 1)
    g2 = FactoryBot.create(:guide_edition, panopticon_id: artefact2.id, version_number: 1)
    g3 = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, version_number: 2)
    assert_equal [], g2.siblings.to_a
    assert_equal [g3], g1.siblings.to_a
  end

  test "it should be able to find its previous siblings" do
    artefact2 = FactoryBot.create(:artefact)
    g1 = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, version_number: 1)
    FactoryBot.create(:guide_edition, panopticon_id: artefact2.id, version_number: 1)
    g3 = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, version_number: 2)

    assert_equal [], g1.previous_siblings.to_a
    assert_equal [g1], g3.previous_siblings.to_a
  end

  test "subsequent and previous siblings are in order" do
    g4 = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, version_number: 4)
    g2 = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, version_number: 2)
    g1 = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, version_number: 1)
    g3 = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, version_number: 3)

    assert_equal [g2, g3, g4], g1.subsequent_siblings.to_a
    assert_equal [g1, g2, g3], g4.previous_siblings.to_a
  end

  context "link validation" do
    should "not be done when the edition is created" do
      assert_difference "AnswerEdition.count", 1 do
        FactoryBot.create(:answer_edition, body: 'abc [foobar](http://foobar.com "hover")')
      end
    end

    should "be done when an existing edition is updated" do
      edition = FactoryBot.create(:answer_edition, body: 'abc [foobar](http://foobar.com "hover")')

      edition.body += "some update"

      assert_not edition.valid?
      assert_equal edition.errors.full_messages, ["Body Don't include hover text in links. Delete the text in quotation marks eg \"This appears when you hover over the link.\""]
    end

    should "allow archiving an edition with invalid links" do
      edition = FactoryBot.create(:answer_edition, state: "published", body: 'abc [foobar](http://foobar.com "hover")')

      assert_difference "Edition.archived.count", 1 do
        edition.archive!
      end
    end
  end

  context "change note" do
    should "be a minor change by default" do
      edition = FactoryBot.create(:edition, title: "Edition")

      assert_not edition.major_change
    end
    should "not be valid for major changes with a blank change note" do
      edition = FactoryBot.build(:edition, title: "Edition", change_note: "", major_change: true)

      assert_not edition.valid?
      assert edition.errors.key?(:change_note)
    end
    should "be valid for major changes with a change note" do
      edition = FactoryBot.create(:edition, title: "Edition", major_change: true, change_note: "Changed")
      assert edition.valid?
    end
    should "be valid when blank for minor changes" do
      edition = FactoryBot.create(:edition, title: "Edition", change_note: "")

      assert edition.valid?
    end
    should "be valid when populated for minor changes" do
      edition = FactoryBot.create(:edition, title: "Edition", change_note: "Changed")

      assert edition.valid?
    end
  end

  test "reviewer cannot be the assignee" do
    user = FactoryBot.create(:user)
    edition = FactoryBot.build(:edition,
                               title: "Edition",
                               version_number: 1,
                               panopticon_id: 123,
                               state: "in_review",
                               review_requested_at: Time.zone.now,
                               assigned_to: user)
    edition.reviewer = user.name
    assert_not edition.valid?
    assert edition.errors.key?(:reviewer)
  end

  context "#build_clone" do
    should "clone common edition fields" do
      edition = FactoryBot.create(
        :edition,
        :published,
        overview: "I am a test overview",
        title: "I am a test title",
        in_beta: true,
        owning_org_content_ids: %w[org-1],
      )
      clone_edition = edition.build_clone

      assert_equal edition.editionable.class, clone_edition.editionable.class
      assert_equal edition.panopticon_id, clone_edition.panopticon_id
      assert_equal edition.overview, clone_edition.overview
      assert_equal edition.title, clone_edition.title
      assert_equal edition.in_beta, clone_edition.in_beta
      assert_equal edition.slug, clone_edition.slug
      assert_equal edition.owning_org_content_ids, clone_edition.owning_org_content_ids
    end

    should "should not copy the mongo_id" do
      edition = FactoryBot.create(:guide_edition, :published, mongo_id: "12345mongo")
      clone_edition = edition.build_clone

      assert_nil clone_edition.mongo_id
    end

    should "increment the version number" do
      edition = FactoryBot.create(:guide_edition, :published)
      new_edition = edition.build_clone
      assert_equal edition.version_number + 1, new_edition.version_number
    end

    should "prevent cloning from a non-published edition" do
      edition = FactoryBot.create(:guide_edition)

      error = assert_raise(RuntimeError) do
        edition.build_clone
      end
      assert_equal "Cloning of non published edition not allowed", error.message
    end

    should "prevent cloning from a published edition with a subsequent in-progress sibling" do
      edition = FactoryBot.create(:guide_edition, :published)
      FactoryBot.create(:guide_edition, panopticon_id: edition.panopticon_id)

      error = assert_raise(RuntimeError) do
        edition.build_clone
      end
      assert_equal "Cloning of a published edition when an in-progress edition exists is not allowed", error.message
    end

    # test cloning into different edition types
    Edition.delegated_types.map(&:constantize).permutation(2).each do |source_class, destination_class|
      next if [source_class, destination_class].include?(PopularLinksEdition)

      should "clone a #{source_class} into a #{destination_class}" do
        # Note that the new edition won't necessarily be valid - for example the
        # new type might have required fields that the old just doesn't have.
        # This is OK because when Publisher saves the clone, it already skips
        # validations. The user will then be required to populate those values
        # before they save the edition again.
        source_edition = FactoryBot.create(source_class.to_s.underscore.to_sym, :published)

        assert_nothing_raised do
          source_edition.build_clone(destination_class)
        end
      end
    end

    should "clone from a GuideEdition into an AnswerEdition" do
      edition = FactoryBot.create(
        :guide_edition,
        :published,
        overview: "I am a test overview",
        title: "I am a title",
        video_url: "http://www.youtube.com/watch?v=dQw4w9WgXcQ",
      )
      new_edition = edition.build_clone AnswerEdition

      assert_equal AnswerEdition, new_edition.editionable.class
      assert_equal 2, new_edition.version_number
      assert_equal edition.panopticon_id, new_edition.panopticon_id
      assert_equal "draft", new_edition.state
      assert_equal "I am a test overview", new_edition.overview
      assert_equal "I am a title", new_edition.title
      assert_equal edition.whole_body, new_edition.whole_body
    end

    should "clone GuideEdition parts into an AnswerEdition" do
      edition = FactoryBot.create(:guide_edition, :published)
      edition.parts.build(title: "Some Part Title!", body: "This is some **version** text.", slug: "part-one")
      edition.parts.build(title: "Another Part Title", body: "This is [link](http://example.net/) text.", slug: "part-two")
      edition.save!
      new_edition = edition.build_clone AnswerEdition

      assert_equal AnswerEdition, new_edition.editionable.class
      assert_equal "# Some Part Title!\n\nThis is some **version** text.\n\n# Another Part Title\n\nThis is [link](http://example.net/) text.", edition.whole_body
      assert_equal edition.whole_body, new_edition.whole_body
    end

    should "clone from a TransactionEdition into an AnswerEdition" do
      edition = FactoryBot.create(
        :transaction_edition,
        :published,
        overview: "I am a test overview",
        more_information: "More information",
        alternate_methods: "Alternate methods",
      )
      new_edition = edition.build_clone AnswerEdition

      assert_equal AnswerEdition, new_edition.editionable.class
      assert_equal 2, new_edition.version_number
      assert_equal edition.panopticon_id, new_edition.panopticon_id
      assert_equal "draft", new_edition.state
      assert_equal "I am a test overview", new_edition.overview
      assert_equal edition.whole_body, new_edition.whole_body
    end

    should "clone from a SimpleSmartAnswerEdition into an AnswerEdition" do
      edition = FactoryBot.create(:simple_smart_answer_edition, :published, overview: "I am a test overview")

      new_edition = edition.build_clone AnswerEdition

      assert_equal AnswerEdition, new_edition.editionable.class
      assert_equal 2, new_edition.version_number
      assert_equal edition.panopticon_id, new_edition.panopticon_id
      assert_equal "draft", new_edition.state
      assert_equal "I am a test overview", new_edition.overview
      assert_equal edition.whole_body, new_edition.whole_body
    end

    should "clone from an AnswerEdition into a TransactionEdition" do
      edition = FactoryBot.create(
        :answer_edition,
        :published,
        overview: "I am a test overview",
        body: "Test body",
      )
      new_edition = edition.build_clone TransactionEdition

      assert_equal TransactionEdition, new_edition.editionable.class
      assert_equal 2, new_edition.version_number
      assert_equal edition.panopticon_id, new_edition.panopticon_id
      assert_equal "draft", new_edition.state
      assert_equal "I am a test overview", new_edition.overview
      assert_equal "Test body", new_edition.more_information
    end

    should "clone from an AnswerEdition into a SimpleSmartAnswerEdition" do
      edition = FactoryBot.create(
        :answer_edition,
        :published,
        overview: "I am a test overview",
        body: "Test body",
      )
      new_edition = edition.build_clone SimpleSmartAnswerEdition

      assert_equal SimpleSmartAnswerEdition, new_edition.editionable.class
      assert_equal 2, new_edition.version_number
      assert_equal edition.panopticon_id, new_edition.panopticon_id
      assert_equal "draft", new_edition.state
      assert_equal "I am a test overview", new_edition.overview
      assert_equal "Test body", new_edition.body
    end

    should "clone from a GuideEdition into a TransactionEdition" do
      edition = FactoryBot.create(
        :guide_edition,
        :published,
        overview: "I am a test overview",
        video_url: "http://www.youtube.com/watch?v=dQw4w9WgXcQ",
      )
      new_edition = edition.build_clone TransactionEdition

      assert_equal TransactionEdition, new_edition.editionable.class
      assert_equal 2, new_edition.version_number
      assert_equal edition.panopticon_id, new_edition.panopticon_id
      assert_equal "draft", new_edition.state
      assert_equal "I am a test overview", new_edition.overview
      assert_equal edition.whole_body, new_edition.more_information
    end

    should "clone from an AnswerEdition into a GuideEdition" do
      edition = FactoryBot.create(
        :answer_edition,
        :published,
        overview: "I am a test overview",
        title: "I am a title",
        body: "I am a body",
      )
      new_edition = edition.build_clone GuideEdition
      new_edition.save!

      assert_equal GuideEdition, new_edition.editionable.class
      assert_equal 2, new_edition.version_number
      assert_equal edition.panopticon_id, new_edition.panopticon_id
      assert_equal "draft", new_edition.state
      assert_equal "I am a test overview", new_edition.overview
      assert_equal "I am a title", new_edition.title
      assert_equal "# Part One\n\nI am a body", new_edition.whole_body
    end

    should "create a clone with an empty list of actions" do
      edition = FactoryBot.create(:guide_edition, :published)
      new_edition = edition.build_clone
      assert_equal [], new_edition.actions
    end

    should "create a clone whose fields are independent of the original edition" do
      edition = FactoryBot.create(:guide_edition_with_two_parts, :published)

      new_edition = edition.build_clone
      new_edition.parts.first.body = "Some other version text"

      original_text = edition.parts.map(&:body).join(" ")
      new_text = new_edition.parts.map(&:body).join(" ")
      assert_not_equal original_text, new_text
    end
  end

  test "knows the common fields of two edition subclasses" do
    to_copy = Set.new(%i[introduction need_to_know more_information])
    transaction_edition = FactoryBot.create(:transaction_edition)
    result = Set.new(transaction_edition.fields_to_copy(PlaceEdition))

    assert to_copy.proper_subset?(result)
  end

  test "edition finder should return the published edition when given an empty edition parameter" do
    dummy_publication = template_published_answer
    template_unpublished_answer(2)

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
    assert_not dummy_publication.has_video?
  end

  test "should create a publication based on data imported from panopticon" do
    artefact = FactoryBot.create(
      :artefact,
      slug: "foo-bar",
      kind: "answer",
      name: "Foo bar",
      owning_app: "publisher",
    )
    artefact.save!

    Artefact.find(artefact.id)
    user = FactoryBot.create(:user, :govuk_editor)

    publication = Edition.find_or_create_from_panopticon_data(artefact.id, user)

    assert_kind_of AnswerEdition, publication.editionable
    assert_equal artefact.name, publication.title
    assert_equal artefact.id.to_s, publication.panopticon_id.to_s
  end

  test "should create a publication with the current user as the assignee" do
    artefact = FactoryBot.create(
      :artefact,
      slug: "foo-bar",
      kind: "answer",
      name: "Foo bar",
      owning_app: "publisher",
    )
    artefact.save!

    Artefact.find(artefact.id)
    user = FactoryBot.create(:user, :govuk_editor)

    publication = Edition.find_or_create_from_panopticon_data(artefact.id, user)

    assert_equal user.id.to_s, publication.assigned_to_id.to_s
  end

  test "should not change edition metadata if archived" do
    artefact = FactoryBot.create(
      :artefact,
      slug: "foo-bar",
      kind: "answer",
      name: "Foo bar",
      owning_app: "publisher",
    )

    guide = FactoryBot.create(
      :guide_edition,
      panopticon_id: artefact.id,
      title: "Original title",
      slug: "original-title",
      state: "archived",
    )
    artefact.slug = "new-slug"
    artefact.save!

    assert_not_equal "new-slug", guide.reload.slug
  end

  test "should scope publications by assignee" do
    a, b = 2.times.map { FactoryBot.create(:guide_edition, panopticon_id: @artefact.id) }

    alice, bob, charlie = %w[alice bob charlie].map do |s|
      FactoryBot.create(:user, :govuk_editor, name: s)
    end
    alice.assign(a, bob)
    alice.assign(a, charlie)
    alice.assign(b, bob)

    assert_equal [b], Edition.assigned_to(bob).to_a
  end

  test "should scope publications by state" do
    draft_guide = FactoryBot.create(:guide_edition, state: "draft")
    FactoryBot.create(:guide_edition, state: "published")

    assert_equal [draft_guide], Edition.where(state: %w[draft]).to_a
  end

  test "should scope publications by partial title match" do
    guide = FactoryBot.create(:guide_edition, title: "Hitchhiker's Guide to the Galaxy")
    FactoryBot.create(:guide_edition)

    assert_equal [guide], Edition.search_title_and_slug("Galaxy").to_a
  end

  test "should scope publications by case-insensitive title match" do
    guide = FactoryBot.create(:guide_edition, title: "Hitchhiker's Guide to the Galaxy")
    FactoryBot.create(:guide_edition)

    assert_equal [guide], Edition.search_title_and_slug("Hitchhiker's gUIDE to the Galaxy").to_a
  end

  test "cannot delete a publication that has been published" do
    dummy_answer = template_published_answer
    loaded_answer = Edition.where(slug: "childcare").first

    assert_equal loaded_answer, dummy_answer
    assert_not dummy_answer.can_destroy?
    assert_raise Workflow::CannotDeletePublishedPublication do
      dummy_answer.destroy
    end
  end

  test "cannot delete a published publication with a new draft edition" do
    dummy_answer = template_published_answer

    new_edition = dummy_answer.build_clone
    new_edition.body = "Two"
    dummy_answer.save!

    assert_raise Edition::CannotDeletePublishedPublication do
      dummy_answer.destroy
    end
  end

  test "can delete a publication that has not been published" do
    dummy_answer = template_unpublished_answer
    dummy_answer.destroy!

    loaded_answer = Edition.where(slug: dummy_answer.slug).first
    assert_nil loaded_answer
  end

  test "deleting a newer draft of a published edition removes sibling information" do
    user1 = FactoryBot.create(:user, :govuk_editor)
    edition = Edition.find_or_create_from_panopticon_data(@artefact.id, user1)
    edition.update!(state: "published")
    second_edition = edition.build_clone
    second_edition.save!
    edition.reload

    assert edition.sibling_in_progress

    second_edition.destroy!
    edition.reload

    assert_nil edition.sibling_in_progress
  end

  test "the latest edition should remove sibling_in_progress details if it is present" do
    user1 = FactoryBot.create(:user, :govuk_editor)
    edition = Edition.find_or_create_from_panopticon_data(@artefact.id, user1)
    edition.update!(state: "published")

    # simulate a document having a newer edition destroyed (previous behaviour).
    edition.sibling_in_progress = 2
    edition.save!(validate: false)

    assert edition.can_create_new_edition?
  end

  test "should also delete associated artefact" do
    user1 = FactoryBot.create(:user, :govuk_editor)
    edition = Edition.find_or_create_from_panopticon_data(@artefact.id, user1)

    assert_difference "Artefact.count", -1 do
      edition.destroy
    end
  end

  test "should not delete associated artefact if there are other editions of this publication" do
    user1 = FactoryBot.create(:user, :govuk_editor)
    edition = Edition.find_or_create_from_panopticon_data(@artefact.id, user1)
    edition.update!(state: "published")

    second_edition = edition.build_clone
    second_edition.save!

    assert_no_difference "Artefact.count" do
      second_edition.destroy
    end
  end

  test "should scope publications assigned to nobody" do
    a, b = 2.times.map { |_i| FactoryBot.create(:guide_edition, panopticon_id: @artefact.id) }

    alice, bob, charlie = %w[alice bob charlie].map do |s|
      FactoryBot.create(:user, :govuk_editor, name: s)
    end

    alice.assign(a, bob)

    assert_equal bob, a.assigned_to

    alice.assign(a, charlie)

    assert_equal charlie, a.assigned_to

    assert_equal 2, Edition.count
    assert_equal [b], Edition.assigned_to(nil).to_a
    assert_equal [], Edition.assigned_to(bob).to_a
    assert_equal [a], Edition.assigned_to(charlie).to_a
  end

  test "given multiple editions, can return the most recent published edition" do
    edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, slug: "hedgehog-topiary", state: "published")

    second_edition = edition.build_clone
    edition.update!(state: "archived")
    second_edition.update!(state: "published")

    third_edition = second_edition.build_clone
    third_edition.update!(state: "draft")

    assert_equal edition.published_edition, second_edition
  end

  test "editions, by default, return their title for use in the admin-interface lists of publications" do
    edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    assert_equal edition.title, edition.admin_list_title
  end

  test "editions can have notes stored for the history tab" do
    edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    user = User.new
    assert edition.new_action(user, "note", comment: "Something important")
  end

  test "status should not be affected by notes" do
    user = User.create!(name: "bob")
    edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    edition.new_action(user, Action::APPROVE_REVIEW)
    edition.new_action(user, Action::NOTE, comment: "Something important")

    assert_equal Action::APPROVE_REVIEW, edition.latest_status_action.request_type
  end

  test "should have no assignee by default" do
    edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    assert_nil edition.assigned_to
  end

  test "should be assigned to the last assigned recipient" do
    alice = FactoryBot.create(:user, :govuk_editor, name: "alice")
    bob = FactoryBot.create(:user, :govuk_editor, name: "bob")
    edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    alice.assign(edition, bob)
    assert_equal bob, edition.assigned_to
  end

  test "cannot assign if user does not have correct editor permissions" do
    alice = FactoryBot.create(:user, name: "alice")
    bob = FactoryBot.create(:user, :govuk_editor, name: "bob")
    edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    alice.assign(edition, bob)
    assert_nil edition.assigned_to
  end

  test "cannot assign if recipient does not have correct editor permissions" do
    alice = FactoryBot.create(:user, :govuk_editor, name: "alice")
    bob = FactoryBot.create(:user, name: "bob")
    edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    alice.assign(edition, bob)
    assert_nil edition.assigned_to
  end

  test "a new guide has no published edition" do
    guide = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    assert_nil Edition.where(state: "published", panopticon_id: guide.panopticon_id).first
  end

  test "an edition of a guide can be published" do
    edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    edition.publish
    assert_not_nil Edition.where(state: "published", panopticon_id: edition.panopticon_id).first
  end

  test "should archive older editions, even if there are validation errors, when a new edition is published" do
    edition = FactoryBot.create(:guide_edition_with_two_parts, panopticon_id: @artefact.id, state: "ready")

    user = FactoryBot.create(:user, :govuk_editor, name: "bob")
    publish(user, edition, "First publication")

    second_edition = edition.build_clone
    second_edition.state = "ready"
    second_edition.save!

    publish(user, second_edition, "Second publication")

    # simulate link validation errors in published edition
    second_edition.parts.first.body = "[register your vehicle](registering-an-imported-vehicle)"
    second_edition.parts.first.save!(validate: false)

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

    assert_equal 2, Edition.where(panopticon_id: edition.panopticon_id, state: "archived").count
  end

  test "when an edition is published, publish_at is cleared" do
    user = FactoryBot.create(:user, :govuk_editor)
    edition = FactoryBot.create(:edition, :scheduled_for_publishing)

    publish(user, edition, "First publication")

    assert_nil edition.reload.publish_at
  end

  test "edition can return latest status action of a specified request type" do
    edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "draft")
    user = FactoryBot.create(:user, :govuk_editor, name: "George")
    request_review(user, edition)

    assert_equal edition.actions.size, 1
    assert edition.latest_status_action(Action::REQUEST_REVIEW).present?
  end

  test "a published edition can't be edited" do
    edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "published")
    edition.title = "My New Title"

    assert_not edition.save
    assert_equal ["Published editions can't be edited"], edition.errors[:base]
  end

  test "edition's publish history is recorded" do
    edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")

    user = FactoryBot.create(:user, :govuk_editor, name: "bob")
    publish(user, edition, "First publication")

    second_edition = edition.build_clone
    second_edition.update!(state: "ready")
    second_edition.save!
    publish(user, second_edition, "Second publication")

    third_edition = second_edition.build_clone
    third_edition.update!(state: "ready")
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
    edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")

    user = FactoryBot.create(:user, :govuk_editor, name: "bob")
    publish(user, edition, "First publication")

    new_edition = edition.build_clone
    new_edition.state = "ready"
    new_edition.save!
    publish(user, new_edition, "Second publication")

    edition = edition.reload

    assert_nil edition.sibling_in_progress
  end

  test "a series with one published and one draft edition should have a sibling in progress" do
    edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    edition.save!

    user = FactoryBot.create(:user, :govuk_editor, name: "bob")
    publish(user, edition, "First publication")

    new_edition = edition.build_clone
    new_edition.save!

    edition = edition.reload

    assert_not_nil edition.sibling_in_progress
    assert_equal new_edition.version_number, edition.sibling_in_progress
  end

  test "a part's slug must be of the correct format" do
    edition_one = FactoryBot.build(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    edition_one.parts.build title: "Part One", body: "Never gonna give you up", slug: "part-One-1"
    edition_one.save!

    edition_one.parts[0].slug = "part one"
    assert_raise ActiveRecord::RecordInvalid do
      edition_one.save!
    end
  end

  test "parts can be sorted by the order field using a scope" do
    edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "ready", title: "One", slug: "one")
    edition.parts.create! title: "Biscuits", body: "Never gonna give you up", slug: "biscuits", order: 2
    edition.parts.create! title: "Cookies", body: "NYAN NYAN NYAN NYAN", slug: "cookies", order: 1
    edition.save!

    assert_equal "Cookies", edition.parts.in_order.first.title
    assert_equal "Biscuits", edition.parts.in_order.last.title
  end

  test "user should not be able to review an edition they requested review for" do
    user = User.create!(name: "Mary")

    edition = FactoryBot.create(:edition, title: "Childcare", slug: "childcare", panopticon_id: @artefact.id)
    assert edition.can_request_review?
    request_review(user, edition)
    assert_not request_amendments(user, edition)
  end

  test "a published publication with a draft edition is in progress" do
    dummy_answer = template_published_answer
    assert_not dummy_answer.has_sibling_in_progress?

    edition = dummy_answer.build_clone
    edition.save!

    dummy_answer.reload
    assert dummy_answer.has_sibling_in_progress?
  end

  test "a draft edition cannot be published" do
    edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "draft")
    assert_not edition.can_publish?
  end

  # test denormalisation

  test "should denormalise an edition with an assigned user and action requesters" do
    user1 = FactoryBot.create(:user, name: "Morwenna")
    user2 = FactoryBot.create(:user, name: "John")
    user3 = FactoryBot.create(:user, name: "Nick")

    FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "archived")

    edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "archived", assigned_to_id: user1.id)
    edition.actions.create! request_type: Action::CREATE, requester: user2
    edition.actions.create! request_type: Action::PUBLISH, requester: user3
    edition.actions.create! request_type: Action::ARCHIVE, requester: user1
    edition.save! && edition.reload

    assert_equal user1.name, edition.assignee
    assert_equal user2.name, edition.creator
    assert_equal user3.name, edition.publisher
    assert_equal user1.name, edition.archiver
  end

  test "should denormalise an assignee's name when an edition is assigned" do
    user1 = FactoryBot.create(:user, :govuk_editor)
    user2 = FactoryBot.create(:user, :govuk_editor)

    edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "draft")
    user1.assign edition, user2

    assert_equal user2, edition.assigned_to
    assert_equal user2.name, edition.assignee
  end

  test "should denormalise a creator's name when an edition is created" do
    user = FactoryBot.create(:user, :govuk_editor)
    artefact = FactoryBot.create(
      :artefact,
      slug: "foo-bar",
      kind: "answer",
      name: "Foo bar",
      owning_app: "publisher",
    )

    edition = Edition.find_or_create_from_panopticon_data(artefact.id, user)

    assert_equal user.name, edition.creator
  end

  test "should denormalise a publishing user's name when an edition is published" do
    user = FactoryBot.create(:user, :govuk_editor)

    edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    publish(user, edition, "First publication")

    assert_equal user.name, edition.publisher
  end

  test "should set siblings in progress to nil for new editions" do
    FactoryBot.create(:user, :govuk_editor)
    edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "published")
    assert_equal 1, edition.version_number
    assert_nil edition.sibling_in_progress
  end

  test "should update previous editions when new edition is added" do
    FactoryBot.create(:user)
    FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "archived")
    published_edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "published")
    new_edition = published_edition.build_clone
    new_edition.save!
    published_edition.reload

    assert_equal 3, new_edition.version_number
    assert_equal 3, published_edition.sibling_in_progress
  end

  test "should update previous editions when new edition is published" do
    user = FactoryBot.create(:user, :govuk_editor)
    FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "archived")
    published_edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, state: "published")

    new_edition = published_edition.build_clone
    new_edition.save!
    new_edition.update!(state: "ready")
    publish(user, new_edition, "First publication")

    assert_equal 3, new_edition.version_number
    assert_nil new_edition.sibling_in_progress
    assert_nil published_edition.reload.sibling_in_progress
  end

  test "all subclasses except popular links should provide a working whole_body method for diffing" do
    Edition.delegated_types.each do |klass|
      next if klass == "PopularLinksEdition"

      klass = Object.const_get(klass)

      assert klass.instance_methods.include?(:whole_body), "#{klass} doesn't provide a whole_body"
      assert_nothing_raised do
        klass.new.whole_body
      end
    end
  end

  test "should not allow any changes to an edition with an archived artefact" do
    user = FactoryBot.create(:user, :govuk_editor, uid: "123", name: "Ben")
    artefact = FactoryBot.build(:artefact)
    artefact.save_as user
    guide_edition = user.create_edition(:guide, title: "some title", state: "draft", panopticon_id: artefact.id)
    artefact.update_as user, state: "archived"

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
      ed = FactoryBot.build(:edition, panopticon_id: @artefact.id)
      ed.version_number = nil
      assert_not ed.valid?, "Expected edition not to be valid with no version_number"
    end

    should "be unique" do
      ed1 = FactoryBot.create(:edition, panopticon_id: @artefact.id)
      ed2 = FactoryBot.build(:edition, panopticon_id: @artefact.id)
      ed2.version_number = ed1.version_number

      assert_not ed2.valid?, "Expected edition not to be valid with conflicting version_number"
    end

    should "allow editions belonging to different artefacts to have matching version_numbers" do
      ed1 = FactoryBot.create(:edition, panopticon_id: @artefact.id)
      ed2 = FactoryBot.build(:edition, panopticon_id: FactoryBot.create(:artefact).id)
      ed2.version_number = ed1.version_number

      assert ed2.valid?, "Expected edition to be valid"
    end

    should "have a database-level constraint on the uniqueness" do
      ed1 = FactoryBot.create(:edition, panopticon_id: @artefact.id)
      ed2 = FactoryBot.build(:edition, panopticon_id: @artefact.id)
      ed2.version_number = ed1.version_number

      assert_raises ActiveRecord::RecordNotUnique do
        ed2.save! validate: false
      end
    end
  end

  context "indexable_content" do
    context "editions with a 'body'" do
      should "include the body with markup removed" do
        edition = FactoryBot.create(:answer_edition, body: "## Title", panopticon_id: FactoryBot.create(:artefact).id)
        assert_equal "Title", edition.indexable_content
      end
    end

    context "for a single part thing" do
      should "have an empty string for an edition with no body" do
        edition = FactoryBot.create(:guide_edition, state: "ready", title: "one part thing", panopticon_id: FactoryBot.create(:artefact).id)
        edition.publish
        assert_equal "", edition.indexable_content
      end
    end

    context "for a multi part thing" do
      should "have the normalised content of all parts" do
        edition = FactoryBot.create(:guide_edition_with_two_parts, state: "ready", panopticon_id: FactoryBot.create(:artefact).id)
        edition.publish
        assert_equal "PART ! This is some version text. PART !! This is some more version text.", edition.indexable_content
      end
    end

    context "indexable_content would contain govspeak" do
      should "convert it to plaintext" do
        edition = FactoryBot.create(:guide_edition_with_two_govspeak_parts, state: "ready", panopticon_id: FactoryBot.create(:artefact).id)
        edition.publish

        expected = "Some Part Title! This is some version text. Another Part Title This is link text."
        assert_equal expected, edition.indexable_content
      end
    end
  end

  context "#latest_major_update" do
    should "return the most recent published edition with a major change" do
      edition1 = FactoryBot.create(
        :answer_edition,
        major_change: true,
        change_note: "published",
        state: "published",
        version_number: 1,
      )
      edition2 = edition1.build_clone

      edition2.update!(major_change: true, change_note: "changed", state: "published")
      edition1.update!(state: "archived")

      edition3 = edition2.build_clone

      assert_equal edition2.id, edition3.latest_major_update.id
    end
  end

  context "#latest_change_note" do
    should "return the change note of the latest major update" do
      edition1 = FactoryBot.create(
        :answer_edition,
        major_change: true,
        change_note: "a change note",
        state: "published",
      )
      edition2 = edition1.build_clone

      assert_equal "a change note", edition2.latest_change_note
    end

    should "return nil if there is no major update in the edition series" do
      edition1 = FactoryBot.create(
        :answer_edition,
        major_change: false,
        state: "published",
      )
      assert_nil edition1.latest_change_note
    end
  end

  context "#public_updated_at" do
    should "return the updated_at timestamp of the latest major update" do
      edition1 = FactoryBot.create(
        :answer_edition,
        major_change: true,
        change_note: "a change note",
        updated_at: 1.minute.ago,
        state: "published",
      )
      edition2 = edition1.build_clone

      assert_in_delta edition1.updated_at, edition2.public_updated_at, 1.second
    end

    should "return the timestamp of the first published edition when there are no major updates" do
      edition1 = FactoryBot.create(
        :answer_edition,
        major_change: false,
        updated_at: 2.minutes.ago,
        state: "published",
      )
      edition2 = edition1.build_clone
      Timecop.freeze(1.minute.ago) do
        # added to allow significant amount of time between edition updated_at values
        edition2.update!(state: "published", major_change: false)
      end
      edition1.update!(state: "archived", major_change: false)

      assert_in_delta edition1.updated_at, edition2.public_updated_at, 1.second
      assert_not_in_delta edition2.updated_at, edition2.public_updated_at, 1.second
    end

    should "return nil if there are no major updates and no published editions" do
      edition1 = FactoryBot.create(
        :answer_edition,
        major_change: false,
        updated_at: 1.minute.ago,
        state: "draft",
      )

      assert_nil edition1.public_updated_at
    end
  end

  context "#has_ever_been_published?" do
    should "return true if any edition has a published state" do
      edition1 = FactoryBot.create(
        :answer_edition,
        major_change: false,
        updated_at: 2.minutes.ago,
        state: "published",
      )
      edition2 = edition1.build_clone
      edition2.update!(state: "archived", major_change: false)
      edition4 = FactoryBot.create(
        :answer_edition,
        major_change: false,
        updated_at: 2.minutes.ago,
        state: "draft",
      )

      assert_equal true, edition1.has_ever_been_published?
      assert_equal true, edition2.has_ever_been_published?
      assert_equal false, edition4.has_ever_been_published?
    end
  end

  context "#first_edition_of_published" do
    should "return the first edition of a series that has at least one edition state published" do
      edition1 = FactoryBot.create(
        :answer_edition,
        major_change: false,
        updated_at: 2.minutes.ago,
        state: "published",
      )
      edition2 = edition1.build_clone
      edition1.update!(state: "archived", major_change: false)
      edition2.update!(state: "published", major_change: false)
      edition3 = edition2.build_clone
      edition3.update!(state: "archived", major_change: false)

      assert_equal edition1, edition1.first_edition_of_published
      assert_equal edition1, edition2.first_edition_of_published
      assert_equal edition1, edition3.first_edition_of_published
    end
  end

  context "link_check_reports" do
    should "not have any link_check_reports by default" do
      edition = FactoryBot.create(:edition, :published)
      assert_equal 0, edition.link_check_reports.size
    end

    should "add a new link_check_report" do
      edition = FactoryBot.create(:edition, :published)
      edition.link_check_reports.build(FactoryBot.attributes_for(:link_check_report))
      assert_equal 1, edition.link_check_reports.size
    end
  end

  context "latest_link_check_report" do
    should "be nil if no reports" do
      edition = FactoryBot.create(:edition, :published)
      assert_nil edition.latest_link_check_report
    end

    should "return the last report created" do
      edition = FactoryBot.create(:edition, :published)
      edition.link_check_reports.create!(FactoryBot.attributes_for(:link_check_report))
      latest_report = edition.link_check_reports.create!(FactoryBot.attributes_for(:link_check_report, batch_id: 2))

      assert latest_report, edition.latest_link_check_report
    end
  end

  context "where the body contains a line separator character" do
    should "remove character on save with 2 part edition" do
      edition = FactoryBot.create(:guide_edition_with_two_parts)
      edition.parts.first.body = "Some text \u2028with a line separator character"
      edition.save!

      assert_no_match(/\u2028/, edition.parts.first.body)
    end
  end

  context "#paths" do
    should "include the base path" do
      edition = FactoryBot.create(:guide_edition, slug: "test-path")
      assert_equal edition.paths, ["/test-path"]
    end

    should "include any parts" do
      edition = FactoryBot.create(:guide_edition, slug: "test-path")
      edition.parts.create!(title: "Test title", body: "Test body", slug: "test-part")
      assert_equal edition.paths, ["/test-path", "/test-path/test-part"]
    end
  end

  context "when 'restrict_access_by_org' feature toggle is enabled" do
    setup do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:restrict_access_by_org, true)
    end

    teardown do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:restrict_access_by_org, false)
    end

    context "accessible_to scope" do
      should "omit editions that are owned by an organisation that is different to the user's when user has departmental_editor permission" do
        FactoryBot.create(:edition, owning_org_content_ids: %w[one])
        user = FactoryBot.create(:user, :departmental_editor, organisation_content_id: "two")

        query_result = Edition.accessible_to(user)

        assert_empty query_result
      end

      should "omit editions that are owned by an organisation when the user has no organisation and has departmental_editor permission" do
        FactoryBot.create(:edition, owning_org_content_ids: %w[one])
        user = FactoryBot.create(:user, :departmental_editor, organisation_content_id: nil)

        query_result = Edition.accessible_to(user)

        assert_empty query_result
      end

      should "omit editions not owned by any organisation when user has departmental_editor permission" do
        FactoryBot.create(:edition, owning_org_content_ids: [])
        user = FactoryBot.create(:user, :departmental_editor, organisation_content_id: "two")

        query_result = Edition.accessible_to(user)

        assert_empty query_result
      end

      should "omit editions not owned by any organisation when the user has no organisation and has departmental_editor permission" do
        FactoryBot.create(:edition, owning_org_content_ids: [])
        user = FactoryBot.create(:user, :departmental_editor, organisation_content_id: nil)

        query_result = Edition.accessible_to(user)

        assert_empty query_result
      end

      should "include editions that are owned by the user's organisation" do
        FactoryBot.create(:edition, owning_org_content_ids: %w[one])
        user = FactoryBot.create(:user, organisation_content_id: "one")

        query_result = Edition.accessible_to(user)

        assert_equal 1, query_result.count
      end

      should "include editions that are not owned by any organisation, when the user's organisation is GDS" do
        FactoryBot.create(:edition, owning_org_content_ids: [])
        user = FactoryBot.create(:user, organisation_content_id: PublishService::GDS_ORGANISATION_ID)

        query_result = Edition.accessible_to(user)

        assert_equal 1, query_result.count
      end

      should "include editions that are owned by an organisation that is different to the user's, when the user's organisation is GDS" do
        FactoryBot.create(:edition, owning_org_content_ids: %w[one])
        user = FactoryBot.create(:user, organisation_content_id: PublishService::GDS_ORGANISATION_ID)

        query_result = Edition.accessible_to(user)

        assert_equal 1, query_result.count
      end
    end

    context "#is_accessible_to?" do
      should "return false for editions that are owned by an organisation that is different to the user's and user has departmental_editor permission" do
        edition = FactoryBot.create(:edition, owning_org_content_ids: %w[one])
        user = FactoryBot.create(:user, :departmental_editor, organisation_content_id: "two")

        assert_not edition.is_accessible_to?(user)
      end

      should "return false for editions that are owned by an organisation when the user has no organisation and has departmental_editor permission" do
        edition = FactoryBot.create(:edition, owning_org_content_ids: %w[one])
        user = FactoryBot.create(:user, :departmental_editor, organisation_content_id: nil)

        assert_not edition.is_accessible_to?(user)
      end

      should "return false for editions not owned by any organisation and user has departmental_editor permission" do
        edition = FactoryBot.create(:edition, owning_org_content_ids: [])
        user = FactoryBot.create(:user, :departmental_editor, organisation_content_id: "two")

        assert_not edition.is_accessible_to?(user)
      end

      should "return false for editions not owned by any organisation when the user has no organisation and has departmental_editor permission" do
        edition = FactoryBot.create(:edition, owning_org_content_ids: [])
        user = FactoryBot.create(:user, :departmental_editor, organisation_content_id: nil)

        assert_not edition.is_accessible_to?(user)
      end

      should "return true for editions that are owned by the user's organisation" do
        edition = FactoryBot.create(:edition, owning_org_content_ids: %w[one])
        user = FactoryBot.create(:user, organisation_content_id: "one")

        assert edition.is_accessible_to?(user)
      end

      should "return true for editions that are not owned by any organisation, when the user's organisation is GDS" do
        edition = FactoryBot.create(:edition, owning_org_content_ids: [])
        user = FactoryBot.create(:user, organisation_content_id: PublishService::GDS_ORGANISATION_ID)

        assert edition.is_accessible_to?(user)
      end

      should "return true for editions that are owned by an organisation that is different to the user's, when the user's organisation is GDS" do
        edition = FactoryBot.create(:edition, owning_org_content_ids: %w[one])
        user = FactoryBot.create(:user, organisation_content_id: PublishService::GDS_ORGANISATION_ID)

        assert edition.is_accessible_to?(user)
      end
    end
  end

  context "when 'restrict_access_by_org' feature toggle is disabled" do
    setup do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:restrict_access_by_org, false)
    end

    context "accessible_to scope" do
      should "include editions that are owned by an organisation that is different to the user's" do
        FactoryBot.create(:edition, owning_org_content_ids: %w[one])
        user = FactoryBot.create(:user, organisation_content_id: "two")

        query_result = Edition.accessible_to(user)

        assert_equal 1, query_result.count
      end

      should "include editions that are owned by an organisation when the user has no organisation" do
        FactoryBot.create(:edition, owning_org_content_ids: %w[one])
        user = FactoryBot.create(:user, organisation_content_id: nil)

        query_result = Edition.accessible_to(user)

        assert_equal 1, query_result.count
      end

      should "include editions not owned by any organisation" do
        FactoryBot.create(:edition, owning_org_content_ids: [])
        user = FactoryBot.create(:user, organisation_content_id: "two")

        query_result = Edition.accessible_to(user)

        assert_equal 1, query_result.count
      end

      should "include editions not owned by any organisation when the user has no organisation" do
        FactoryBot.create(:edition, owning_org_content_ids: [])
        user = FactoryBot.create(:user, organisation_content_id: nil)

        query_result = Edition.accessible_to(user)

        assert_equal 1, query_result.count
      end

      should "include editions that are owned by the user's organisation" do
        FactoryBot.create(:edition, owning_org_content_ids: %w[one])
        user = FactoryBot.create(:user, organisation_content_id: "one")

        query_result = Edition.accessible_to(user)

        assert_equal 1, query_result.count
      end

      should "include editions that are not owned by any organisation, when the user's organisation is GDS" do
        FactoryBot.create(:edition, owning_org_content_ids: [])
        user = FactoryBot.create(:user, organisation_content_id: PublishService::GDS_ORGANISATION_ID)

        query_result = Edition.accessible_to(user)

        assert_equal 1, query_result.count
      end

      should "include editions that are owned by an organisation that is different to the user's, when the user's organisation is GDS" do
        FactoryBot.create(:edition, owning_org_content_ids: %w[one])
        user = FactoryBot.create(:user, organisation_content_id: PublishService::GDS_ORGANISATION_ID)

        query_result = Edition.accessible_to(user)

        assert_equal 1, query_result.count
      end
    end

    context "#is_accessible_to?" do
      should "return true for editions that are owned by an organisation that is different to the user's" do
        edition = FactoryBot.create(:edition, owning_org_content_ids: %w[one])
        user = FactoryBot.create(:user, organisation_content_id: "two")

        assert edition.is_accessible_to?(user)
      end

      should "return true for editions that are owned by an organisation when the user has no organisation" do
        edition = FactoryBot.create(:edition, owning_org_content_ids: %w[one])
        user = FactoryBot.create(:user, organisation_content_id: nil)

        assert edition.is_accessible_to?(user)
      end

      should "return true for editions not owned by any organisation" do
        edition = FactoryBot.create(:edition, owning_org_content_ids: [])
        user = FactoryBot.create(:user, organisation_content_id: "two")

        assert edition.is_accessible_to?(user)
      end

      should "return true for editions not owned by any organisation when the user has no organisation" do
        edition = FactoryBot.create(:edition, owning_org_content_ids: [])
        user = FactoryBot.create(:user, organisation_content_id: nil)

        assert edition.is_accessible_to?(user)
      end

      should "return true for editions that are owned by the user's organisation" do
        edition = FactoryBot.create(:edition, owning_org_content_ids: %w[one])
        user = FactoryBot.create(:user, organisation_content_id: "one")

        assert edition.is_accessible_to?(user)
      end

      should "return true for editions that are not owned by any organisation, when the user's organisation is GDS" do
        edition = FactoryBot.create(:edition, owning_org_content_ids: [])
        user = FactoryBot.create(:user, organisation_content_id: PublishService::GDS_ORGANISATION_ID)

        assert edition.is_accessible_to?(user)
      end

      should "return true for editions that are owned by an organisation that is different to the user's, when the user's organisation is GDS" do
        edition = FactoryBot.create(:edition, owning_org_content_ids: %w[one])
        user = FactoryBot.create(:user, organisation_content_id: PublishService::GDS_ORGANISATION_ID)

        assert edition.is_accessible_to?(user)
      end
    end
  end

  context "#is_editable_by?" do
    should "return true when edition is in editable state and user has edit permissions" do
      user = FactoryBot.create(:user)
      edition = FactoryBot.create(:edition, :draft)

      user.stubs(:has_editor_permissions?).returns(true)

      assert edition.is_editable_by?(user)
    end

    should "return false when Edition is scheduled for publishing" do
      user = FactoryBot.create(:user)
      edition = FactoryBot.create(:edition, :scheduled_for_publishing)

      user.stubs(:has_editor_permissions?).returns(true)

      assert_not edition.is_editable_by?(user)
    end

    should "return false when Edition is archived" do
      user = FactoryBot.create(:user)
      edition = FactoryBot.create(:edition, :archived)

      user.stubs(:has_editor_permissions?).returns(true)

      assert_not edition.is_editable_by?(user)
    end

    should "return false when Edition is published" do
      user = FactoryBot.create(:user)
      edition = FactoryBot.create(:edition, :published)

      user.stubs(:has_editor_permissions?).returns(true)

      assert_not edition.is_editable_by?(user)
    end

    should "return false when user does not have editor permissions" do
      user = FactoryBot.create(:user)
      edition = FactoryBot.create(:edition, :draft)

      user.stubs(:has_editor_permissions?).returns(false)

      assert_not edition.is_editable_by?(user)
    end
  end
end
