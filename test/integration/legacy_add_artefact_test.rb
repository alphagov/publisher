require "legacy_integration_test_helper"

class LegacyAddArtefactTest < LegacyIntegrationTest
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

  should "create a CompletedTransaction artefact" do
    visit root_path
    click_link "Add artefact"

    fill_in "Title", with: "Thingy McThingface"
    fill_in "Slug", with: "done/stick-a-fork-in-me-im"
    select "Completed transaction", from: "Format"

    click_button "Save and go to item"

    assert %r{^/editions/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]*$} =~ page.current_path

    completed_transaction = CompletedTransactionEdition.last
    assert completed_transaction.edition.artefact.name == "Thingy McThingface"
    assert completed_transaction.edition.artefact.slug == "done/stick-a-fork-in-me-im"
  end

  should "create a Transaction artefact" do
    visit root_path
    click_link "Add artefact"

    fill_in "Title", with: "Register for space flight"
    fill_in "Slug", with: "register-for-space-flight"
    select "Transaction", from: "Format"

    click_button "Save and go to item"

    assert %r{^/editions/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]*$} =~ page.current_path

    transaction = TransactionEdition.last
    assert transaction.edition.artefact.name == "Register for space flight"
    assert transaction.edition.artefact.slug == "register-for-space-flight"
  end

  should "create a LocalTransaction artefact" do
    LocalService.create!(lgsl_code: 1, providing_tier: %w[county unitary])

    @artefact = FactoryBot.create(
      :artefact,
      slug: "hedgehog-topiary",
      kind: "local_transaction",
      name: "Foo bar",
      owning_app: "publisher",
    )

    visit "/publications/#{@artefact.id}"
    fill_in "LGSL code", with: "1"
    fill_in "LGIL code", with: "2"

    click_button "Create Local transaction"

    assert %r{^/editions/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]*$} =~ page.current_path

    local_transaction = LocalTransactionEdition.last
    assert local_transaction.edition.artefact.name == "Foo bar"
    assert local_transaction.edition.artefact.slug == "hedgehog-topiary"
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
