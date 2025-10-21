require "integration_test_helper"

class EditionHistoryJSTest < JavascriptIntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    login_as(@govuk_editor)

    stub_events_for_all_content_ids
    stub_users_from_signon_api

    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_edit_phase_2, true)
    test_strategy.switch!(:design_system_edit_phase_3a, true)
  end

  context "History and notes tab" do
    setup do
      visit_draft_edition
      click_link("History and notes")
    end

    should "expand the first entry in the accordion by default" do
      assert page.has_css?(".govuk-accordion__section-toggle-text", text: "Hide")
    end
  end

  def create_draft_edition
    @draft_edition = FactoryBot.create(:edition, title: "Edit page title", state: "draft", overview: "metatags", in_beta: 1, body: "The body")
  end

  def visit_draft_edition
    create_draft_edition
    visit edition_path(@draft_edition)
  end
end
