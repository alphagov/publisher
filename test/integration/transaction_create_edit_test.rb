require "legacy_integration_test_helper"

class TransactionCreateEditTest < LegacyJavascriptIntegrationTest
  setup do
    @artefact = FactoryBot.create(
      :artefact,
      slug: "register-for-space-flight",
      kind: "transaction",
      name: "Register for space flight",
      owning_app: "publisher",
    )

    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
    stub_events_for_all_content_ids
    stub_users_from_signon_api
    UpdateWorker.stubs(:perform_async)

    login_as @author
  end

  with_and_without_javascript do
    should "edit a new TransactionEdition" do
      visit "/publications/#{@artefact.id}"

      assert page.has_content? @artefact.name

      fill_in "Introductory paragraph", with: "Become a space pilot"
      choose "Sign in"
      fill_in "Will continue on", with: "UK Space Recruitment"
      fill_in "More information", with: "Take part in the final frontier"

      save_edition_and_assert_success
      assert page.has_content? @artefact.name

      transaction = TransactionEdition.first
      assert_equal @artefact.id.to_s, transaction.panopticon_id

      assert_equal "Become a space pilot", transaction.introduction
      assert_equal "Sign in", transaction.start_button_text
      assert_equal "UK Space Recruitment", transaction.will_continue_on
      assert_equal "Take part in the final frontier", transaction.more_information
    end

    should "allow editing a TransactionEdition" do
      transaction = FactoryBot.create(
        :transaction_edition,
        panopticon_id: @artefact.id,
        title: "Register for space flight",
        introduction: "Become a space pilot",
        will_continue_on: "UK Space Recruitment",
      )

      visit_edition transaction

      assert page.has_content? "Register for space flight"
      assert page.has_field?("Introductory paragraph", with: "Become a space pilot")
      assert page.has_field?("Will continue on", with: "UK Space Recruitment")

      fill_in "Introductory paragraph", with: "Get your licence to fly to Mars"
      fill_in "Will continue on", with: "UK Terrestrial Mars Office"

      save_edition_and_assert_success

      t = TransactionEdition.find(transaction.id)
      assert_equal "Get your licence to fly to Mars", t.introduction
      assert_equal "UK Terrestrial Mars Office", t.will_continue_on
    end
  end

  should "disable fields for a published edition" do
    edition = FactoryBot.create(
      :transaction_edition,
      panopticon_id: @artefact.id,
      state: "published",
      slug: @artefact.slug,
      title: "Foo transaction",
    )

    visit_edition edition
    assert_all_edition_fields_disabled(page)
  end
end
