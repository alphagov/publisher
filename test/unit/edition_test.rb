require 'test_helper'

class EditionTest < ActiveSupport::TestCase

  context "single registration" do
    should "register with panopticon when published" do
      user = FactoryGirl.create(:user)
      artefact = FactoryGirl.create(:artefact)
      edition = FactoryGirl.create(:guide_edition, :state => "ready", panopticon_id: artefact.id)

      registerable = mock("registerable_edition")
      RegisterableEdition.expects(:new).with(edition).returns(registerable)
      GdsApi::Panopticon::Registerer.any_instance.expects(:register).with(registerable)
      user.publish(edition, comment: "I am bananas")
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
end
