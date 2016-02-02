require 'test_helper'

class EditionTest < ActiveSupport::TestCase

  context "single registration" do
    should "register with panopticon when published" do
      user = FactoryGirl.create(:user)
      artefact = FactoryGirl.create(:artefact)
      edition = FactoryGirl.create(:guide_edition, :state => "ready", panopticon_id: artefact.id)

      registerable = mock("registerable_edition")
      PublishingAPIPublisher.stubs(:perform_async)
      RegisterableEdition.expects(:new).with(edition).returns(registerable)
      GdsApi::Panopticon::Registerer.any_instance.expects(:register).with(registerable)
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
      publish(user, edition)
    end

    should "not register with Panopticon if the artefact is archived" do
      user = FactoryGirl.create(:user)
      artefact = FactoryGirl.create(:artefact)
      edition = FactoryGirl.create(:guide_edition, :state => "ready", panopticon_id: artefact.id)

      # Doing this after creating the edition, so the edition doesn't try to
      # update the artefact
      artefact.update_attributes! state: "archived"

      registerable = mock("registerable_edition")
      RegisterableEdition.stubs(:new).with(edition).returns(registerable)
      GdsApi::Panopticon::Registerer.any_instance.expects(:register).never

      assert_raises Edition::ResurrectionError do
        edition.register_with_panopticon
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

    exception = assert_raises(StateMachine::InvalidTransition) { edition.publish_anonymously! }
    assert_match "Cannot transition state via :publish from :ready (Reason(s): Parts", exception.message
    assert_match "Internal links must start with a forward slash", exception.message
  end
end
