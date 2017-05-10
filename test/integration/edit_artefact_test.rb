require "integration_test_helper"

class EditArtefactTest < ActionDispatch::IntegrationTest
  setup do
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
  end

  should "edit a draft artefact" do
    edition = FactoryGirl.create(:edition)
    visit metadata_edition_path(edition)

    fill_in "Slug", with: ""
    click_button "Update metadata"

    assert page.has_content?("Slug can't be blank")

    fill_in "Slug", with: "thingy-mc-thingface"

    UpdateWorker.expects(:perform_async).with(edition.id.to_s)
    click_button "Update metadata"
    edition.reload

    assert page.has_content?("Metadata updated")
    assert edition.artefact.slug == "thingy-mc-thingface"
  end

  should "not be able to edit metadata for a published edition" do
    edition = FactoryGirl.create(:edition, :published)
    visit metadata_edition_path(edition)

    assert !page.has_button?("Update metadata")
  end
end
