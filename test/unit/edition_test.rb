require 'test_helper'

class EditionTest < ActiveSupport::TestCase

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

  test "should update Rummager on publication with no parts" do
    edition = FactoryGirl.create(:guide_edition, :state => 'ready')
    edition.stubs(:search_index).returns("stuff for search index")

    Rummageable.expects(:index).with("stuff for search index")
    user = FactoryGirl.create(:user)
    user.publish(edition, comment: 'Testing')
  end

  test "should update Rummager on deletion" do
    artefact = FactoryGirl.create(:artefact,
        slug: "hedgehog-topiary",
        kind: "guide",
        name: "Foo bar",
        owning_app: "publisher",
    )

    user = User.create
    edition = Edition.find_or_create_from_panopticon_data(artefact.id, user, {})

    Rummageable.expects(:delete).with("/hedgehog-topiary")
    edition.destroy
  end

  test "struct for search index" do
    dummy_publication = template_published_answer
    out = dummy_publication.search_index
    assert_equal ["title", "link", "format", "description", "indexable_content", "section", "subsection"], out.keys
  end

  test "search index for all publications" do
    dummy_publication = template_published_answer
    out = Edition.search_index_all
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

  test "a published publication with a draft edition is in progress" do
    dummy_answer = template_published_answer
    assert !dummy_answer.has_sibling_in_progress?

    edition = dummy_answer.build_clone
    edition.save

    dummy_answer.reload
    assert dummy_answer.has_sibling_in_progress?
  end

  test "a series with one published and one draft edition should have a sibling in progress" do
    without_metadata_denormalisation(GuideEdition) do
      edition = FactoryGirl.create(:guide_edition, state: "ready")
      edition.save!

      user = User.create name: "bob"
      user.publish edition, comment: "First publication"

      new_edition = edition.build_clone
      new_edition.save!

      edition = edition.reload

      assert_not_nil edition.sibling_in_progress
      assert_equal new_edition.version_number, edition.sibling_in_progress
    end
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

  test "should also delete associated artefact" do
    FactoryGirl.create(:tag, tag_id: "test-section", title: "Test section", tag_type: "section")
    artefact = FactoryGirl.create(:artefact,
                                  slug: "foo-bar",
                                  kind: "answer",
                                  name: "Foo bar",
                                  primary_section: "test-section",
                                  sections: ["test-section"],
                                  department: "Test dept",
                                  owning_app: "publisher")

    user1 = FactoryGirl.create(:user)
    edition = AnswerEdition.find_or_create_from_panopticon_data(artefact.id, user1, {})

    assert_difference "Artefact.count", -1 do
      edition.destroy
    end
  end

  test "should denormalise a creator's name when an edition is created" do
    @user = FactoryGirl.create(:user)
    FactoryGirl.create(:tag, tag_id: "test-section", title: "Test section", tag_type: "section")
    artefact = FactoryGirl.create(:artefact,
                                  slug: "foo-bar",
                                  kind: "answer",
                                  name: "Foo bar",
                                  primary_section: "test-section",
                                  sections: ["test-section"],
                                  department: "Test dept",
                                  owning_app: "publisher")

    edition = AnswerEdition.find_or_create_from_panopticon_data(artefact.id, @user, {})

    assert_equal @user.name, edition.creator
  end

  test "should denormalise a publishing user's name when an edition is published" do
    @user = FactoryGirl.create(:user)

    edition = FactoryGirl.create(:guide_edition, state: "ready")
    @user.publish edition, { }

    assert_equal @user.name, edition.publisher
  end

  test "should denormalise an assignee's name when an edition is assigned" do
    @user1 = FactoryGirl.create(:user)
    @user2 = FactoryGirl.create(:user)

    edition = FactoryGirl.create(:guide_edition, state: "lined_up")
    @user1.assign edition, @user2

    assert_equal @user2, edition.assigned_to
    assert_equal @user2.name, edition.assignee
  end

  test "should set siblings in progress to nil for new editions" do
    @user = FactoryGirl.create(:user)
    @edition = FactoryGirl.create(:guide_edition, state: "ready")
    @published_edition = FactoryGirl.create(:guide_edition, state: "published")
    assert_equal 1, @edition.version_number
    assert_nil @edition.sibling_in_progress
  end

  test "when an edition of a guide is published, all other published editions are archived" do
    without_metadata_denormalisation(GuideEdition) do
      edition = FactoryGirl.create(:guide_edition, state: "ready")

      user = User.create name: "bob"
      user.publish edition, comment: "First publication"

      second_edition = edition.build_clone
      second_edition.update_attribute(:state, "ready")
      second_edition.save!
      user.publish second_edition, comment: "Second publication"

      third_edition = second_edition.build_clone
      third_edition.update_attribute(:state, "ready")
      third_edition.save!
      user.publish third_edition, comment: "Third publication"

      edition.reload
      assert edition.archived?

      second_edition.reload
      assert second_edition.archived?

      assert_equal 2, GuideEdition.where(panopticon_id: edition.panopticon_id, state: "archived").count
    end
  end

  test "should denormalise an edition with an assigned user and action requesters" do
    @user1 = FactoryGirl.create(:user, name: "Morwenna")
    @user2 = FactoryGirl.create(:user, name: "John")
    @user3 = FactoryGirl.create(:user, name: "Nick")

    edition = FactoryGirl.create(:guide_edition, state: "archived")

    edition = FactoryGirl.create(:guide_edition, state: "archived", assigned_to_id: @user1.id)
    edition.actions.create request_type: Action::CREATE, requester: @user2
    edition.actions.create request_type: Action::PUBLISH, requester: @user3
    edition.actions.create request_type: Action::ARCHIVE, requester: @user1
    edition.save! and edition.reload

    assert_equal @user1.name, edition.assignee
    assert_equal @user2.name, edition.creator
    assert_equal @user3.name, edition.publisher
    assert_equal @user1.name, edition.archiver
  end

  test "should update previous editions when new edition is added" do
    @user = FactoryGirl.create(:user)
    @edition = FactoryGirl.create(:guide_edition, state: "ready")
    @published_edition = FactoryGirl.create(:guide_edition, state: "published")
    @new_edition = @published_edition.build_clone
    @new_edition.save
    @published_edition.reload

    assert_equal 2, @new_edition.version_number
    assert_equal 2, @published_edition.sibling_in_progress
  end

  test "check counting reviews" do
    user = User.create(name: "Ben")
    other_user = User.create(name: "James")

    edition = user.create_edition(:guide, title: "My Title", slug: "my-title", panopticon_id: "12345678")

    assert_equal 0, edition.rejected_count

    user.start_work(edition)
    user.request_review(edition, {comment: "Review this guide please."})
    other_user.request_amendments(edition, {comment: "I've reviewed it"})

    assert_equal 1, edition.rejected_count

    user.request_review(edition,{comment: "Review this guide please."})
    other_user.approve_review(edition, {comment: "Looks good to me"})

    assert_equal 1, edition.rejected_count
  end
end
