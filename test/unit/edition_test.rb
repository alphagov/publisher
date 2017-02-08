require 'test_helper'

class EditionTest < ActiveSupport::TestCase

  context "single registration" do
    should "register with rummager, publising-api when published" do
      user = FactoryGirl.create(:user)
      artefact = FactoryGirl.create(:artefact)
      edition = FactoryGirl.create(:guide_edition, :state => "ready", panopticon_id: artefact.id)

      registerable = mock("registerable_edition")
      PublishingAPIPublisher.expects(:perform_async)
      RegisterableEdition.expects(:new).with(edition).returns(registerable)
      SearchIndexer.expects(:call).with(registerable)

      publish(user, edition)
    end

    should "use the edition's snake_cased format for kind, not the artefact's kind (it may have changed)" do
      user = FactoryGirl.create(:user)
      artefact = FactoryGirl.create(:artefact, kind: "answer")
      edition = FactoryGirl.create(:local_transaction_edition, :state => "ready", panopticon_id: artefact.id, lgsl_code: FactoryGirl.create(:local_service).lgsl_code)

      stub_register_published_content

      publish(user, edition)
    end

    should "not register with Rummager, publishing-api if the artefact is archived" do
      user = FactoryGirl.create(:user)
      artefact = FactoryGirl.create(:artefact)
      edition = FactoryGirl.create(:guide_edition, :state => "ready", panopticon_id: artefact.id)

      # Doing this after creating the edition, so the edition doesn't try to
      # update the artefact
      artefact.update_attributes! state: "archived"

      registerable = mock("registerable_edition")
      RegisterableEdition.stubs(:new).with(edition).returns(registerable)
      SearchIndexer.expects(:call).with(registerable).never

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

  should "notify the publishing-api when published" do
    edition = FactoryGirl.create(:guide_edition, state: "ready")
    PublishingAPIPublisher.expects(:perform_async).with(edition.id.to_s)
    SearchIndexer.stubs(:call)
    user = FactoryGirl.create(:user)
    publish(user, edition)
  end

  should "raise an exception when publish_anonymously! fails to publish" do
    edition = FactoryGirl.create(:guide_edition_with_two_parts, state: "ready")
    # simulate validation error causing failure to publish anonymously
    edition.parts.first.update_attribute(:body, "[register your vehicle](registering-an-imported-vehicle)")

    exception = assert_raises(StateMachines::InvalidTransition) { edition.publish_anonymously! }
    assert_match "Cannot transition state via :publish from :ready (Reason(s): Parts", exception.message
    assert_match "Internal links must start with a forward slash", exception.message
  end

  context "#fact_check_id" do
    context "for a migrated format" do
      should "return a deterministic hex id if edition is in fact-check state" do
        edition = FactoryGirl.create(:edition, state: 'fact_check', id: 123)
        edition.artefact.update_attribute(:kind, 'help_page')
        assert_equal edition.fact_check_id, "a665a459-2042-4f9d-817e-4867efdc4fb8"
      end

      should "return a deterministic hex id if edition is in fact-check-received state" do
        edition = FactoryGirl.create(:edition, state: 'fact_check_received', id: 123)
        edition.artefact.update_attribute(:kind, 'help_page')
        assert_equal edition.fact_check_id, "a665a459-2042-4f9d-817e-4867efdc4fb8"
      end

      should "return a deterministic hex id if edition is in ready state" do
        edition = FactoryGirl.create(:edition, state: 'ready', id: 123)
        edition.artefact.update_attribute(:kind, 'help_page')
        assert_equal edition.fact_check_id, "a665a459-2042-4f9d-817e-4867efdc4fb8"
      end

      should "return nil if edition is in in any other state" do
        edition = FactoryGirl.create(:edition, state: 'draft')
        edition.artefact.update_attribute(:kind, 'help_page')
        assert_nil edition.fact_check_id
      end
    end

    context "for a format that has not yet been migrated" do
      should "return nil" do
        edition = FactoryGirl.create(:edition, state: 'fact_check_received', id: 123)
        assert_nil edition.fact_check_id
      end
    end
  end
end
