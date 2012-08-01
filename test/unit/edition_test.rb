require 'test_helper'

class EditionTest < ActiveSupport::TestCase

  context "single registration" do
    should "register with panopticon when published" do
      user = FactoryGirl.create(:user)
      artefact = FactoryGirl.create(:artefact)
      edition = FactoryGirl.create(:guide_edition, :state => 'ready', panopticon_id: artefact.id)

      registerable = mock("registerable_edition")
      RegisterableEdition.expects(:new).with(edition).returns(registerable)
      GdsApi::Panopticon::Registerer.any_instance.expects(:register).with(registerable)
      user.publish(edition, comment: "I am bananas")
    end
  end
end
