require "legacy_integration_test_helper"

class DeleteEditionTest < LegacyIntegrationTest
  setup do
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
    stub_events_for_all_content_ids
    stub_users_from_signon_api
  end

  teardown do
    GDS::SSO.test_user = nil
  end

  context "when an artefact has multiple editions" do
    should "discard the draft in the publishing api" do
      artefact = FactoryBot.create(:artefact, kind: "guide")
      edition = FactoryBot.create(:guide_edition, panopticon_id: artefact.id)

      visit_edition edition

      click_on "Admin"

      Services.publishing_api.expects(:discard_draft).with(artefact.content_id, locale: artefact.language)

      click_button "Delete this edition – #1"

      within(".alert-success") do
        assert page.has_content?("Edition deleted")
      end
    end
  end

  context "when an artefact has only one edition" do
    should "discard the draft in the publishing api" do
      artefact = FactoryBot.create(:artefact, :with_published_edition, kind: "guide")
      edition = FactoryBot.create(:guide_edition, panopticon_id: artefact.id)

      visit_edition edition

      click_on "Admin"

      Services.publishing_api.expects(:discard_draft).with(artefact.content_id, locale: artefact.language)

      click_button "Delete this edition – #2"

      within(".alert-success") do
        assert page.has_content?("Edition deleted")
      end
    end
  end
end
