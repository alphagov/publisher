require 'test_helper'

class EditionTest < ActiveSupport::TestCase
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

  should "raise an exception when publish_anonymously! fails to publish" do
    edition = FactoryBot.create(:guide_edition_with_two_parts, state: "ready")
    # simulate validation error causing failure to publish anonymously
    edition.parts.first.update_attribute(:body, "[register your vehicle](registering-an-imported-vehicle)")

    exception = assert_raises(StateMachines::InvalidTransition) { edition.publish_anonymously! }
    assert_match "Cannot transition state via :publish from :ready (Reason(s): Parts", exception.message
    assert_match "Internal links must start with a forward slash", exception.message
  end

  context "#auth_bypass_id" do
    should "return a deterministic hex id if edition is in fact-check state" do
      edition = FactoryBot.create(:edition, state: 'fact_check', id: 123)
      edition.artefact.update_attribute(:kind, 'help_page')
      assert_equal edition.auth_bypass_id, "a665a459-2042-4f9d-817e-4867efdc4fb8"
    end

    should "return a deterministic hex id if edition is in fact-check-received state" do
      edition = FactoryBot.create(:edition, state: 'fact_check_received', id: 123)
      edition.artefact.update_attribute(:kind, 'help_page')
      assert_equal edition.auth_bypass_id, "a665a459-2042-4f9d-817e-4867efdc4fb8"
    end

    should "return a deterministic hex id if edition is in ready state" do
      edition = FactoryBot.create(:edition, state: 'ready', id: 123)
      edition.artefact.update_attribute(:kind, 'help_page')
      assert_equal edition.auth_bypass_id, "a665a459-2042-4f9d-817e-4867efdc4fb8"
    end
  end
end
