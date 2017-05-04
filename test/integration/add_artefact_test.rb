require "integration_test_helper"

class AddArtefactTest < ActionDispatch::IntegrationTest
  setup do
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
  end

  should "create a new artefact" do
    visit root_path
    click_link "Add artefact"

    fill_in "Title", with: "Thingy McThingface"
    fill_in "Slug", with: "thingy-mc-thingface"
    select "Help page", from: "Format"

    click_button "Save and go to item"

    assert page.has_content?("Help page slugs must have a help/ prefix")

    fill_in "Slug", with: "help/thingy"

    click_button "Save and go to item"

    assert %r{^\/editions\/[a-f0-9]*$} =~ page.current_path

    edition = HelpPageEdition.last
    assert edition.artefact.name == "Thingy McThingface"
    assert edition.artefact.slug == "help/thingy"
  end

  should "not allow the creation of a retired format artefact" do
    visit root_path
    click_link "Add artefact"

    options = find_field("Format").find_all('option').map(&:value)
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
