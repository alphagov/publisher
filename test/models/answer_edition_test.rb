require "test_helper"

class AnswerEditionTest < ActiveSupport::TestCase
  def setup
    @artefact = FactoryBot.create(:artefact)
  end

  def template_answer(version_number = 1)
    artefact = FactoryBot.create(
      :artefact,
      kind: "answer",
      name: "Foo bar",
      owning_app: "publisher",
    )

    AnswerEdition.create!(
      state: "ready",
      slug: "childcare",
      panopticon_id: artefact.id,
      title: "Child care stuff",
      body: "Lots of info",
      version_number:,
    )
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

  # test "it must have a title" do
  #   a = LocalTransactionEdition.new
  #   assert_not a.valid?
  #   assert a.errors[:title].any?
  # end

  # test "it is not in beta by default" do
  #   assert_not FactoryBot.build(:guide_edition).in_beta?
  # end

  # test "it can be in beta" do
  #   assert FactoryBot.build(:guide_edition, in_beta: true).in_beta?
  # end

  # test "it should give a friendly (legacy supporting) description of its format" do
  #   a = LocalTransactionEdition.new
  #   assert_equal "LocalTransaction", a.format
  # end

  # test "it should be able to find its siblings" do
  #   artefact2 = FactoryBot.create(:artefact)
  #   g1 = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, version_number: 1)
  #   g2 = FactoryBot.create(:guide_edition, panopticon_id: artefact2.id, version_number: 1)
  #   g3 = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, version_number: 2)
  #   assert_equal [], g2.siblings.to_a
  #   assert_equal [g3], g1.siblings.to_a
  # end

  # test "it should be able to find its previous siblings" do
  #   artefact2 = FactoryBot.create(:artefact)
  #   g1 = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, version_number: 1)
  #   FactoryBot.create(:guide_edition, panopticon_id: artefact2.id, version_number: 1)
  #   g3 = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, version_number: 2)
  #
  #   assert_equal [], g1.previous_siblings.to_a
  #   assert_equal [g1], g3.previous_siblings.to_a
  # end

  # test "subsequent and previous siblings are in order" do
  #   g4 = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, version_number: 4)
  #   g2 = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, version_number: 2)
  #   g1 = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, version_number: 1)
  #   g3 = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, version_number: 3)
  #
  #   assert_equal [g2, g3, g4], g1.subsequent_siblings.to_a
  #   assert_equal [g1, g2, g3], g4.previous_siblings.to_a
  # end

  # test "A programme should have default parts" do
  #   programme = FactoryBot.create(:programme_edition, panopticon_id: @artefact.id)
  #   assert_equal programme.parts.count, ProgrammeEdition::DEFAULT_PARTS.length
  # end

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

      assert_difference "AnswerEdition.archived.count", 1 do
        edition.archive!
      end
    end
  end

  context "change note" do
    should "be a minor change by default" do
      assert_not AnswerEdition.new.major_change
    end
    should "not be valid for major changes with a blank change note" do
      edition = AnswerEdition.new(major_change: true, change_note: "")
      assert_not edition.valid?
      assert edition.errors.key?(:change_note)
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
    user = FactoryBot.create(:user)
    edition = AnswerEdition.new(
      title: "Edition",
      version_number: 1,
      panopticon_id: 123,
      state: "in_review",
      review_requested_at: Time.zone.now,
      assigned_to: user,
    )
    edition.reviewer = user.name
    assert_not edition.valid?
    assert edition.errors.key?(:reviewer)
  end

  # test "it should build a clone" do
  #   edition = FactoryBot.create(
  #     :guide_edition,
  #     state: "published",
  #     panopticon_id: @artefact.id,
  #     version_number: 1,
  #     overview: "I am a test overview",
  #     in_beta: true,
  #     owning_org_content_ids: %w[org-1],
  #   )
  #   clone_edition = edition.build_clone
  #   assert_equal "I am a test overview", clone_edition.overview
  #   assert_equal true, clone_edition.in_beta
  #   assert_equal 2, clone_edition.version_number
  #   assert_equal %w[org-1], clone_edition.owning_org_content_ids
  # end

  # test "cloning can only occur from a published edition" do
  #   edition = FactoryBot.create(
  #     :guide_edition,
  #     panopticon_id: @artefact.id,
  #     version_number: 1,
  #   )
  #   assert_raise(RuntimeError) do
  #     edition.build_clone
  #   end
  # end

  # test "cloning can only occur from a published edition with no subsequent in progress siblings" do
  #   edition = FactoryBot.create(
  #     :guide_edition,
  #     panopticon_id: @artefact.id,
  #     state: "published",
  #     version_number: 1,
  #   )
  #
  #   FactoryBot.create(
  #     :guide_edition,
  #     panopticon_id: @artefact.id,
  #     state: "draft",
  #     version_number: 2,
  #   )
  #
  #   assert_raise(RuntimeError) do
  #     edition.build_clone
  #   end
  # end

  # test "cloning from an earlier edition should give you a safe version number" do
  #   edition = FactoryBot.create(
  #     :guide_edition,
  #     state: "published",
  #     panopticon_id: @artefact.id,
  #     version_number: 1,
  #   )
  #   FactoryBot.create(
  #     :guide_edition,
  #     state: "published",
  #     panopticon_id: @artefact.id,
  #     version_number: 2,
  #   )
  #
  #   clone1 = edition.build_clone
  #   assert_equal 3, clone1.version_number
  # end

  # test cloning into different edition types
  # Edition.subclasses.permutation(2).each do |source_class, destination_class|
  #   next if source_class.instance_of?(PopularLinksEdition.class) || destination_class.instance_of?(PopularLinksEdition.class)
  #
  #   test "it should be possible to clone from a #{source_class} to a #{destination_class}" do
  #     # Note that the new edition won't necessarily be valid - for example the
  #     # new type might have required fields that the old just doesn't have.
  #     # This is OK because when Publisher saves the clone, it already skips
  #     # validations. The user will then be required to populate those values
  #     # before they save the edition again.
  #     source_edition = FactoryBot.create(:edition, _type: source_class.to_s, state: "published")
  #
  #     assert_nothing_raised do
  #       source_edition.build_clone(destination_class)
  #     end
  #   end
  # end

  # test "Cloning from GuideEdition into AnswerEdition" do
  #   edition = FactoryBot.create(
  #     :guide_edition,
  #     state: "published",
  #     panopticon_id: @artefact.id,
  #     version_number: 1,
  #     overview: "I am a test overview",
  #     video_url: "http://www.youtube.com/watch?v=dQw4w9WgXcQ",
  #   )
  #   new_edition = edition.build_clone AnswerEdition
  #
  #   assert_equal AnswerEdition, new_edition.class
  #   assert_equal 2, new_edition.version_number
  #   assert_equal @artefact.id.to_s, new_edition.panopticon_id
  #   assert_equal "draft", new_edition.state
  #   assert_equal "I am a test overview", new_edition.overview
  #   assert_equal edition.whole_body, new_edition.whole_body
  # end

  # test "Cloning from TransactionEdition into AnswerEdition" do
  #   edition = FactoryBot.create(
  #     :transaction_edition,
  #     state: "published",
  #     panopticon_id: @artefact.id,
  #     version_number: 1,
  #     overview: "I am a test overview",
  #     more_information: "More information",
  #     alternate_methods: "Alternate methods",
  #   )
  #   new_edition = edition.build_clone AnswerEdition
  #
  #   assert_equal AnswerEdition, new_edition.class
  #   assert_equal 2, new_edition.version_number
  #   assert_equal @artefact.id.to_s, new_edition.panopticon_id
  #   assert_equal "draft", new_edition.state
  #   assert_equal "I am a test overview", new_edition.overview
  #   assert_equal edition.whole_body, new_edition.whole_body
  # end

  # test "Cloning from SimpleSmartAnswerEdition into AnswerEdition" do
  #   edition = FactoryBot.create(
  #     :simple_smart_answer_edition,
  #     state: "published",
  #     panopticon_id: @artefact.id,
  #     version_number: 1,
  #     overview: "I am a test overview",
  #   )
  #   new_edition = edition.build_clone AnswerEdition
  #
  #   assert_equal AnswerEdition, new_edition.class
  #   assert_equal 2, new_edition.version_number
  #   assert_equal @artefact.id.to_s, new_edition.panopticon_id
  #   assert_equal "draft", new_edition.state
  #   assert_equal "I am a test overview", new_edition.overview
  #   assert_equal edition.whole_body, new_edition.whole_body
  # end

  # test "Cloning from AnswerEdition into TransactionEdition" do
  #   edition = FactoryBot.create(
  #     :answer_edition,
  #     state: "published",
  #     panopticon_id: @artefact.id,
  #     version_number: 1,
  #     overview: "I am a test overview",
  #     body: "Test body",
  #   )
  #   new_edition = edition.build_clone TransactionEdition
  #
  #   assert_equal TransactionEdition, new_edition.class
  #   assert_equal 2, new_edition.version_number
  #   assert_equal @artefact.id.to_s, new_edition.panopticon_id
  #   assert_equal "draft", new_edition.state
  #   assert_equal "I am a test overview", new_edition.overview
  #   assert_equal "Test body", new_edition.more_information
  # end

  # test "Cloning from AnswerEdition into SimpleSmartAnswerEdition" do
  #   edition = FactoryBot.create(
  #     :answer_edition,
  #     state: "published",
  #     panopticon_id: @artefact.id,
  #     version_number: 1,
  #     overview: "I am a test overview",
  #     body: "Test body",
  #   )
  #   new_edition = edition.build_clone SimpleSmartAnswerEdition
  #
  #   assert_equal SimpleSmartAnswerEdition, new_edition.class
  #   assert_equal 2, new_edition.version_number
  #   assert_equal @artefact.id.to_s, new_edition.panopticon_id
  #   assert_equal "draft", new_edition.state
  #   assert_equal "I am a test overview", new_edition.overview
  #   assert_equal "Test body", new_edition.body
  # end

  # test "Cloning from GuideEdition into TransactionEdition" do
  #   edition = FactoryBot.create(
  #     :guide_edition,
  #     state: "published",
  #     panopticon_id: @artefact.id,
  #     version_number: 1,
  #     overview: "I am a test overview",
  #     video_url: "http://www.youtube.com/watch?v=dQw4w9WgXcQ",
  #   )
  #   new_edition = edition.build_clone TransactionEdition
  #
  #   assert_equal TransactionEdition, new_edition.class
  #   assert_equal 2, new_edition.version_number
  #   assert_equal @artefact.id.to_s, new_edition.panopticon_id
  #   assert_equal "draft", new_edition.state
  #   assert_equal "I am a test overview", new_edition.overview
  #   assert_equal edition.whole_body, new_edition.more_information
  # end
  #
  # test "Cloning from AnswerEdition into GuideEdition" do
  #   edition = FactoryBot.create(
  #     :answer_edition,
  #     state: "published",
  #     panopticon_id: @artefact.id,
  #     version_number: 1,
  #     overview: "I am a test overview",
  #   )
  #   new_edition = edition.build_clone GuideEdition
  #
  #   assert_equal GuideEdition, new_edition.class
  #   assert_equal 2, new_edition.version_number
  #   assert_equal @artefact.id.to_s, new_edition.panopticon_id
  #   assert_equal "draft", new_edition.state
  #   assert_equal "I am a test overview", new_edition.overview
  # end
  #
  # test "knows the common fields of two edition subclasses" do
  #   to_copy = Set.new(%i[introduction need_to_know more_information])
  #   result = Set.new(TransactionEdition.new.fields_to_copy(PlaceEdition))
  #   assert to_copy.proper_subset?(result)
  # end
  #
  # test "edition finder should return the published edition when given an empty edition parameter" do
  #   dummy_publication = template_published_answer
  #   template_unpublished_answer(2)
  #
  #   assert dummy_publication.published?
  #   assert_equal dummy_publication, Edition.find_and_identify("childcare", "")
  # end
  #
  # test "edition finder should return the latest edition when asked" do
  #   dummy_publication = template_published_answer
  #   second_publication = template_unpublished_answer(2)
  #
  #   assert_equal 2, Edition.where(slug: dummy_publication.slug).count
  #   found_edition = Edition.find_and_identify("childcare", "latest")
  #   assert_equal second_publication.version_number, found_edition.version_number
  # end

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

    publication = AnswerEdition.find_or_create_from_panopticon_data(artefact.id, user)

    assert_kind_of AnswerEdition, publication
    assert_equal artefact.name, publication.title
    assert_equal artefact.id.to_s, publication.panopticon_id.to_s
  end

  # test "should create a publication with the current user as the assignee" do
  #   artefact = FactoryBot.create(
  #     :artefact,
  #     slug: "foo-bar",
  #     kind: "answer",
  #     name: "Foo bar",
  #     owning_app: "publisher",
  #   )
  #   artefact.save!
  #
  #   Artefact.find(artefact.id)
  #   user = FactoryBot.create(:user, :govuk_editor)
  #
  #   publication = Edition.find_or_create_from_panopticon_data(artefact.id, user)
  #
  #   assert_equal user.id.to_s, publication.assigned_to_id.to_s
  # end

  # test "should not change edition metadata if archived" do
  #   artefact = FactoryBot.create(
  #     :artefact,
  #     slug: "foo-bar",
  #     kind: "answer",
  #     name: "Foo bar",
  #     owning_app: "publisher",
  #   )
  #
  #   guide = FactoryBot.create(
  #     :guide_edition,
  #     panopticon_id: artefact.id,
  #     title: "Original title",
  #     slug: "original-title",
  #     state: "archived",
  #   )
  #   artefact.slug = "new-slug"
  #   artefact.save!
  #
  #   assert_not_equal "new-slug", guide.reload.slug
  # end
  #
  # test "should scope publications by assignee" do
  #   a, b = 2.times.map { FactoryBot.create(:guide_edition, panopticon_id: @artefact.id) }
  #
  #   alice, bob, charlie = %w[alice bob charlie].map do |s|
  #     FactoryBot.create(:user, :govuk_editor, name: s)
  #   end
  #   alice.assign(a, bob)
  #   alice.assign(a, charlie)
  #   alice.assign(b, bob)
  #
  #   assert_equal [b], Edition.assigned_to(bob).to_a
  # end
  #
  # test "should scope publications by state" do
  #   draft_guide = FactoryBot.create(:guide_edition, state: "draft")
  #   FactoryBot.create(:guide_edition, state: "published")
  #
  #   assert_equal [draft_guide], Edition.in_states(%w[draft]).to_a
  # end
  #
  # test "should scope publications by partial title match" do
  #   guide = FactoryBot.create(:guide_edition, title: "Hitchhiker's Guide to the Galaxy")
  #   FactoryBot.create(:guide_edition)
  #
  #   assert_equal [guide], Edition.title_contains("Galaxy").to_a
  # end
  #
  # test "should scope publications by case-insensitive title match" do
  #   guide = FactoryBot.create(:guide_edition, title: "Hitchhiker's Guide to the Galaxy")
  #   FactoryBot.create(:guide_edition)
  #
  #   assert_equal [guide], Edition.title_contains("Hitchhiker's gUIDE to the Galaxy").to_a
  # end

  test "cannot delete a publication that has been published" do
    dummy_answer = template_published_answer
    loaded_answer = AnswerEdition.where(slug: "childcare").first

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

    loaded_answer = AnswerEdition.where(slug: dummy_answer.slug).first
    assert_nil loaded_answer
  end

  test "deleting a newer draft of a published edition removes sibling information" do
    user1 = FactoryBot.create(:user, :govuk_editor)
    edition = AnswerEdition.find_or_create_from_panopticon_data(@artefact.id, user1)
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
    edition = AnswerEdition.find_or_create_from_panopticon_data(@artefact.id, user1)
    edition.update!(state: "published")

    # simulate a document having a newer edition destroyed (previous behaviour).
    edition.sibling_in_progress = 2
    edition.save!(validate: false)

    assert edition.can_create_new_edition?
  end

  test "should also delete associated artefact" do
    user1 = FactoryBot.create(:user, :govuk_editor)
    edition = AnswerEdition.find_or_create_from_panopticon_data(@artefact.id, user1)

    assert_difference "Artefact.count", -1 do
      edition.destroy
    end
  end

  test "should not delete associated artefact if there are other editions of this publication" do
    user1 = FactoryBot.create(:user, :govuk_editor)
    edition = AnswerEdition.find_or_create_from_panopticon_data(@artefact.id, user1)
    edition.update!(state: "published")

    edition.reload
    second_edition = edition.build_clone
    second_edition.save!

    assert_no_difference "Artefact.count" do
      second_edition.destroy
    end
  end

  # test "should scope publications assigned to nobody" do
  #   a, b = 2.times.map { |_i| FactoryBot.create(:guide_edition, panopticon_id: @artefact.id) }
  #
  #   alice, bob, charlie = %w[alice bob charlie].map do |s|
  #     FactoryBot.create(:user, :govuk_editor, name: s)
  #   end
  #
  #   alice.assign(a, bob)
  #   a.reload
  #   assert_equal bob, a.assigned_to
  #
  #   alice.assign(a, charlie)
  #   a.reload
  #   assert_equal charlie, a.assigned_to
  #
  #   assert_equal 2, Edition.count
  #   assert_equal [b], Edition.assigned_to(nil).to_a
  #   assert_equal [], Edition.assigned_to(bob).to_a
  #   assert_equal [a], Edition.assigned_to(charlie).to_a
  # end

  # test "given multiple editions, can return the most recent published edition" do
  #   edition = FactoryBot.create(:guide_edition, panopticon_id: @artefact.id, slug: "hedgehog-topiary", state: "published")
  #
  #   second_edition = edition.build_clone
  #   edition.update!(state: "archived")
  #   second_edition.update!(state: "published")
  #
  #   third_edition = second_edition.build_clone
  #   third_edition.update!(state: "draft")
  #
  #   assert_equal edition.published_edition, second_edition
  # end
end
