require "legacy_integration_test_helper"

class LocalTransactionCreateEditTest < LegacyJavascriptIntegrationTest
  setup do
    LocalService.create!(lgsl_code: 1, providing_tier: %w[county unitary])

    @artefact = FactoryBot.create(
      :artefact,
      slug: "hedgehog-topiary",
      kind: "local_transaction",
      name: "Foo bar",
      owning_app: "publisher",
    )

    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
    stub_events_for_all_content_ids
    stub_users_from_signon_api
    UpdateWorker.stubs(:perform_async)
  end

  test "creating a local transaction sends the right emails" do
    email_count_before_start = ActionMailer::Base.deliveries.count

    visit "/publications/#{@artefact.id}"
    fill_in "LGSL code", with: "1"
    fill_in "LGIL code", with: "2"

    click_button "Create Local transaction"
    assert page.has_content?(/Foo bar\W#1/)

    assert_operator email_count_before_start + 1, :<=, ActionMailer::Base.deliveries.count
    assert_match(
      "[PUBLISHER] Created Local transaction: \"Foo bar\" (by Author)",
      ActionMailer::Base.deliveries.last.subject,
    )
  end

  test "creating a local transaction with a bad LGSL code displays an appropriate error" do
    visit "/publications/#{@artefact.id}"
    assert page.has_content? "We need a bit more information to create your local transaction."

    fill_in "LGSL code", with: "2"
    click_on "Create Local transaction edition"

    assert page.has_link?("LGSL code is not recognised", href: "#edition_lgsl_code")
  end

  test "creating a local transaction with an empty LGIL code displays an appropriate error" do
    visit "/publications/#{@artefact.id}"
    assert page.has_content? "We need a bit more information to create your local transaction."
    click_on "Create Local transaction edition"

    assert page.has_link?("Enter a LGIL code", href: "#edition_lgil_code")
  end

  test "creating a local transaction with a bad LGIL code displays an appropriate error" do
    visit "/publications/#{@artefact.id}"
    assert page.has_content? "We need a bit more information to create your local transaction."

    fill_in "LGIL code", with: 10.5
    click_on "Create Local transaction edition"

    assert page.has_link?("LGIL code can only be a whole number between 0 and 999", href: "#edition_lgil_code")
  end

  test "creating a local transaction requests an LGSL and a LGIL code" do
    visit "/publications/#{@artefact.id}"
    assert page.has_content? "We need a bit more information to create your local transaction."

    fill_in "LGSL code", with: "1"
    fill_in "LGIL code", with: "2"

    click_button "Create Local transaction"
    assert page.has_content?(/Foo bar\W#1/)
  end

  with_and_without_javascript do
    should "save the LGSL and LGIL fields" do
      edition = FactoryBot.create(
        :local_transaction_edition,
        panopticon_id: @artefact.id,
        slug: @artefact.slug,
        title: "Foo transaction",
        lgsl_code: 1,
        lgil_code: 2,
      )

      visit_edition edition

      assert page.has_content?(/Foo transaction\W#1/)
      assert page.has_field?("LGSL code", with: "1", disabled: true)
      assert page.has_field?("LGIL code", with: "2")

      save_edition_and_assert_success

      edition = LocalTransactionEdition.find(edition.editionable.id)
      assert_equal 2, edition.lgil_code

      # Ensure it gets set to nil when clearing field
      fill_in "LGIL code", with: "3"
      save_edition_and_assert_success

      edition.reload
      assert_equal 3, edition.lgil_code
    end

    should "show an error when the title is empty" do
      edition = FactoryBot.create(
        :local_transaction_edition,
        panopticon_id: @artefact.id,
        slug: @artefact.slug,
        title: "Foo transaction",
        lgsl_code: 1,
        lgil_code: 1,
      )

      visit_edition edition
      fill_in "Title", with: ""

      save_edition_and_assert_error("Enter a title", "#edition_title")
    end

    should "save devolved administration availability fields" do
      edition = FactoryBot.create(
        :local_transaction_edition,
        panopticon_id: @artefact.id,
        slug: @artefact.slug,
        title: "Foo transaction",
        lgsl_code: 1,
        lgil_code: 2,
      )

      visit_edition edition
      choose "Service available from local council", name: "edition[scotland_availability_attributes][authority_type]"
      choose "Service available from devolved administration (or a similar service is available)", name: "edition[wales_availability_attributes][authority_type]"
      fill_in "Enter the URL of the devolved administration website page", with: "https://test-this-slug", name: "edition[wales_availability_attributes][alternative_url]"
      choose "Service not available", name: "edition[northern_ireland_availability_attributes][authority_type]"

      save_edition_and_assert_success
      edition.reload

      scotland_availability = edition.editionable.scotland_availability
      wales_availability = edition.editionable.wales_availability
      northern_ireland_availability = edition.northern_ireland_availability
      assert_equal "local_authority_service", scotland_availability.authority_type
      assert_equal "devolved_administration_service", wales_availability.authority_type
      assert_equal "https://test-this-slug", wales_availability.alternative_url
      assert_equal "unavailable", northern_ireland_availability.authority_type
    end

    should "save cta text field" do
      edition = FactoryBot.create(
        :local_transaction_edition,
        panopticon_id: @artefact.id,
        slug: @artefact.slug,
        title: "Foo transaction",
        lgsl_code: 1,
        lgil_code: 2,
      )

      visit_edition edition

      fill_in "CTA Text", with: "Some test CTA text"
      save_edition_and_assert_success

      edition.reload
      assert_equal "Some test CTA text", edition.editionable.cta_text
    end

    should "save before and after results" do
      edition = FactoryBot.create(
        :local_transaction_edition,
        panopticon_id: @artefact.id,
        slug: @artefact.slug,
        title: "Foo transaction",
        lgsl_code: 1,
        lgil_code: 2,
      )

      visit_edition edition

      fill_in "Before results", with: "Important stuff to know beforehand"
      fill_in "After results", with: "No more to add"
      save_edition_and_assert_success

      edition.reload
      assert_equal "Important stuff to know beforehand", edition.editionable.before_results
      assert_equal "No more to add", edition.editionable.after_results
    end
  end

  should "disable fields for a published edition" do
    edition = FactoryBot.create(
      :local_transaction_edition,
      panopticon_id: @artefact.id,
      state: "published",
      slug: @artefact.slug,
      title: "Foo transaction",
      lgsl_code: 1,
      lgil_code: 1,
    )

    visit_edition edition
    assert_all_edition_fields_disabled(page)
  end
end
