#encoding: utf-8
require 'integration_test_helper'

class LocalTransactionCreateEditTest < JavascriptIntegrationTest
  setup do
    LocalService.create(lgsl_code: 1, providing_tier: %w{county unitary})

    @artefact = FactoryBot.create(:artefact,
        slug: "hedgehog-topiary",
        kind: "local_transaction",
        name: "Foo bar",
        owning_app: "publisher",
                                  )

    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
  end

  test "creating a local transaction sends the right emails" do
    email_count_before_start = ActionMailer::Base.deliveries.count

    visit "/publications/#{@artefact.id}"

    fill_in 'Lgsl code', with: '1'
    fill_in 'Lgil code', with: '2'
    click_button 'Create Local transaction'
    assert page.has_content? 'Foo bar #1'

    assert_equal email_count_before_start + 1, ActionMailer::Base.deliveries.count
    assert_match(
      /Created Local transaction: "Foo bar"/,
      ActionMailer::Base.deliveries.last.subject
    )
  end

  test "creating a local transaction with a bad LGSL code displays an appropriate error" do
    visit "/publications/#{@artefact.id}"
    assert page.has_content? "We need a bit more information to create your local transaction."

    fill_in "Lgsl code", with: "2"
    click_on 'Create Local transaction edition'

    assert page.has_content? "Lgsl code 2 not recognised"
  end

  test "creating a local transaction requests an LGSL and a LGIL code" do
    visit "/publications/#{@artefact.id}"
    assert page.has_content? "We need a bit more information to create your local transaction."

    fill_in 'Lgsl code', with: '1'
    fill_in 'Lgil code', with: '2'

    click_button 'Create Local transaction'
    assert page.has_content? 'Foo bar #1'
  end

  with_and_without_javascript do
    should "save the LGSL and LGIL fields" do
      edition = FactoryBot.create(
        :local_transaction_edition,
        panopticon_id: @artefact.id,
        slug: @artefact.slug,
        title: "Foo transaction",
        lgsl_code: 1,
        lgil_code: 2
      )

      visit_edition edition

      assert page.has_content? 'Foo transaction #1'
      assert page.has_field?('LGSL code', with: '1', disabled: true)
      assert page.has_field?('LGIL code', with: '2')

      save_edition_and_assert_success

      edition = LocalTransactionEdition.find(edition.id)
      assert_equal 2, edition.lgil_code

      # Ensure it gets set to nil when clearing field
      fill_in "LGIL code", with: '3'
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
        lgil_code: 1
      )

      visit_edition edition
      fill_in "Title", with: ""

      save_edition_and_assert_error
    end
  end

  should "disable fields for a published edition" do
    edition = FactoryBot.create(
      :local_transaction_edition,
      panopticon_id: @artefact.id,
      state: 'published',
      slug: @artefact.slug,
      title: "Foo transaction",
      lgsl_code: 1,
      lgil_code: 1
    )

    visit_edition edition
    assert_all_edition_fields_disabled(page)
  end
end
