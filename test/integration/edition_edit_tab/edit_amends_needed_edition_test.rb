require "integration_test_helper"

class EditAmendsNeededEditionTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    login_as(@govuk_editor)
    @test_strategy = Flipflop::FeatureSet.current.test!
    @test_strategy.switch!(:design_system_edit_phase_3a, true)
    @amends_needed_edition = FactoryBot.create(:edition, :amends_needed)

    visit edition_path(@amends_needed_edition)
  end

  should "show 'Send to 2i' link" do
    assert page.has_link?("Send to 2i")
  end

  should "show Preview link" do
    assert page.has_link?("Preview (opens in new tab)")
  end

  should "not show the 'Resend fact check email' link and text" do
    assert page.has_no_link?("Resend fact check email")
    assert page.has_no_text?("You've requested this edition to be fact checked. We're awaiting a response.")
  end

  context "user does not have editor permissions" do
    setup do
      login_as(FactoryBot.create(:user, name: "Non Editor"))
      visit edition_path(@amends_needed_edition)
    end

    should "not show any editable components" do
      assert page.has_no_css?(".govuk-textarea")
      assert page.has_no_css?(".govuk-input")
      assert page.has_no_css?(".govuk-radios")
    end

    should "not show the send to 2i button" do
      assert page.has_no_link?("Send to 2i")
    end

    should "not show the Save button" do
      assert page.has_no_button?("Save")
    end

    should "show the Preview link" do
      assert page.has_link?("Preview (opens in new tab)")
    end
  end
end
