require "legacy_integration_test_helper"

class AddArtefactTest < LegacyIntegrationTest
  setup do
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
    stub_events_for_all_content_ids
    stub_users_from_signon_api
    UpdateWorker.stubs(:perform_async)
  end

  should "create a new artefact" do
    visit root_path
    click_link "Add artefact"

    fill_in "Title", with: "Thingy McThingface"
    fill_in "Slug", with: "thingy-mc-thingface"
    select "Help page", from: "Format"

    click_button "Save and go to item"

    within "#error-summary" do
      assert page.has_content?("There is a problem")
      assert page.has_link?("Help page slugs must have a help/ prefix", href: "#artefact_slug")
    end

    within "#error-slug" do
      assert page.has_content?("Help page slugs must have a help/ prefix")
    end

    fill_in "Slug", with: "help/thingy"

    click_button "Save and go to item"

    assert %r{^/editions/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]*$} =~ page.current_path

    help_page_edition = HelpPageEdition.last
    assert help_page_edition.edition.artefact.name == "Thingy McThingface"
    assert help_page_edition.edition.artefact.slug == "help/thingy"
  end

  should "not allow the creation of a retired format artefact" do
    visit root_path
    click_link "Add artefact"

    options = find_field("Format").find_all("option").map(&:value)
    assert_empty options & Artefact::RETIRED_FORMATS
  end

  should "not allow creation of a done page without the /done prefix" do
    visit root_path
    click_link "Add artefact"

    fill_in "Title", with: "Done thing"
    fill_in "Slug", with: "done-thing"
    select "Completed transaction", from: "Format"

    click_button "Save and go to item"

    assert page.has_content?("Done page slugs must have a done/ prefix")
  end
end
