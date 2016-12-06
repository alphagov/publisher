require 'test_helper'

class EditionTest < ActiveSupport::TestCase

  context "single registration" do
    should "register with panopticon and rummager when published" do
      user = FactoryGirl.create(:user)
      artefact = FactoryGirl.create(:artefact)
      edition = FactoryGirl.create(:guide_edition, :state => "ready", panopticon_id: artefact.id)

      registerable = mock("registerable_edition")
      PublishingAPIPublisher.stubs(:perform_async)
      RegisterableEdition.expects(:new).with(edition).twice.returns(registerable)
      GdsApi::Panopticon::Registerer.any_instance.expects(:register).with(registerable)
      SearchIndexer.expects(:call).with(registerable)

      publish(user, edition)
    end

    should "use the edition's snake_cased format for kind, not the artefact's kind (it may have changed)" do
      user = FactoryGirl.create(:user)
      artefact = FactoryGirl.create(:artefact, kind: "answer")
      edition = FactoryGirl.create(:local_transaction_edition, :state => "ready", panopticon_id: artefact.id, lgsl_code: FactoryGirl.create(:local_service).lgsl_code)

      PublishingAPIPublisher.stubs(:perform_async)
      GdsApi::Panopticon::Registerer
          .expects(:new)
          .with(owning_app: "publisher", rendering_app: "frontend", kind: "local_transaction")
          .returns(stub("registerer", register: nil))
      SearchIndexer.stubs(:call)

      publish(user, edition)
    end

    should "not register with Panopticon or Rummager if the artefact is archived" do
      user = FactoryGirl.create(:user)
      artefact = FactoryGirl.create(:artefact)
      edition = FactoryGirl.create(:guide_edition, :state => "ready", panopticon_id: artefact.id)

      # Doing this after creating the edition, so the edition doesn't try to
      # update the artefact
      artefact.update_attributes! state: "archived"

      registerable = mock("registerable_edition")
      RegisterableEdition.stubs(:new).with(edition).returns(registerable)
      GdsApi::Panopticon::Registerer.any_instance.expects(:register).never
      SearchIndexer.expects(:call).with(registerable).never

      assert_raises Edition::ResurrectionError do
        edition.register_with_panopticon
      end
      assert_raises Edition::ResurrectionError do
        edition.register_with_rummager
      end
    end
  end

  context "state names" do
    should "return an array of symbols" do
      assert Edition.state_names.is_a? Array
      assert Edition.state_names.all? { |name| name.is_a? Symbol }
    end

    should "include the draft and published state" do
      assert_includes Edition.state_names, :draft
      assert_includes Edition.state_names, :published
    end
  end

  should "notify the content store when published" do
    edition = FactoryGirl.create(:guide_edition, state: "ready")
    PublishingAPIPublisher.expects(:perform_async).with(edition.id.to_s)
    GdsApi::Panopticon::Registerer.any_instance.stubs(:register)
    SearchIndexer.stubs(:call)

    user = FactoryGirl.create(:user)
    publish(user, edition)
  end

  should "notify the content store when updated" do
    edition = FactoryGirl.create(:guide_edition, state: "ready")
    PublishingAPIUpdater.expects(:perform_async).with(edition.id.to_s)
    GdsApi::Panopticon::Registerer.any_instance.stubs(:register)

    user = FactoryGirl.create(:user)
    edition.title = "Test guide 3"
    edition.save
  end

  should "raise an exception when publish_anonymously! fails to publish" do
    edition = FactoryGirl.create(:guide_edition_with_two_parts, state: "ready")
    # simulate validation error causing failure to publish anonymously
    edition.parts.first.update_attribute(:body, "[register your vehicle](registering-an-imported-vehicle)")

    exception = assert_raises(StateMachines::InvalidTransition) { edition.publish_anonymously! }
    assert_match "Cannot transition state via :publish from :ready (Reason(s): Parts", exception.message
    assert_match "Internal links must start with a forward slash", exception.message
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
