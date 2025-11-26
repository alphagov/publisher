require "test_helper"

class EditionTest < ActiveSupport::TestCase
  context "state names" do
    should "return an array of symbols" do
      assert Edition.state_names.is_a? Array
      assert(Edition.state_names.all? { |name| name.is_a? Symbol })
    end

    should "include the draft and published state" do
      assert_includes Edition.state_names, :draft
      assert_includes Edition.state_names, :published
    end
  end

  should "raise an exception when publish_anonymously! fails to publish" do
    edition = FactoryBot.build(:guide_edition_with_two_parts, state: "ready")
    # simulate validation error causing failure to publish anonymously
    edition.parts.first.body = "[register your vehicle](registering-an-imported-vehicle)"

    exception = assert_raises(StateMachines::InvalidTransition) { edition.publish_anonymously! }
    assert_match "Cannot transition state via :publish from :ready (Reason(s): Parts", exception.message
    assert_match "Internal links must start with a forward slash", exception.message
  end

  should "generate a unique random auth_bypass_id" do
    edition = FactoryBot.create(:edition)
    assert edition.auth_bypass_id.is_a?(String)
    assert_not edition.auth_bypass_id.empty?

    second_edition = FactoryBot.create(:edition)
    assert_not_equal edition.auth_bypass_id, second_edition.auth_bypass_id
  end
end
