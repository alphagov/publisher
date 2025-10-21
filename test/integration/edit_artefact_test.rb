require "legacy_integration_test_helper"

class EditArtefactTest < LegacyIntegrationTest
  setup do
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
    stub_events_for_all_content_ids
    stub_users_from_signon_api
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_edit_phase_2, false)
    test_strategy.switch!(:design_system_edit_phase_3a, false)
  end

  should "edit a draft artefact" do
    edition = FactoryBot.create(:simple_smart_answer_edition)
    visit metadata_edition_path(edition)

    fill_in "Slug", with: ""
    click_button "Update metadata"

    assert page.has_content?("Enter a slug")

    fill_in "Slug", with: "thingy-mc-thingface"

    UpdateWorker.expects(:perform_async).with(edition.id.to_s)
    click_button "Update metadata"
    edition.reload

    assert page.has_content?("Metadata has successfully updated")
    assert edition.artefact.slug == "thingy-mc-thingface"
  end

  should "not be able to edit metadata for a published edition" do
    edition = FactoryBot.create(:simple_smart_answer_edition, :published)
    visit metadata_edition_path(edition)

    assert_not page.has_button?("Update metadata")
  end
end
