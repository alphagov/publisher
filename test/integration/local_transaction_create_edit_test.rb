#encoding: utf-8
require 'integration_test_helper'

class LocalTransactionCreateEditTest < JavascriptIntegrationTest
  setup do
    LocalService.create(lgsl_code: 1, providing_tier: %w{county unitary})
    LocalAuthority.create(snac: 'ABCDE')

    @artefact = FactoryGirl.create(:artefact,
        slug: "hedgehog-topiary",
        kind: "local_transaction",
        name: "Foo bar",
        owning_app: "publisher",
    )

    setup_users
    stub_collections
  end

  test "creating a local transaction sends the right emails" do
    email_count_before_start = ActionMailer::Base.deliveries.count

    visit "/publications/#{@artefact.id}"

    fill_in 'Lgsl code', :with => '1'
    click_button 'Create Local transaction'
    assert page.has_content? "Viewing “Foo bar” Edition 1"

    assert_equal email_count_before_start + 1, ActionMailer::Base.deliveries.count
    assert_match /Created Local transaction: "Foo bar"/, ActionMailer::Base.deliveries.last.subject
  end

  test "creating a local transaction with a bad LGSL code displays an appropriate error" do
    visit "/publications/#{@artefact.id}"
    assert page.has_content? "We need a bit more information to create your local transaction."

    fill_in "Lgsl code", :with => "2"
    click_on 'Create Local transaction edition'

    assert page.has_content? "Lgsl code 2 not recognised"
  end

  test "creating a local transaction from panopticon requests an LGSL code" do
    visit "/publications/#{@artefact.id}"
    assert page.has_content? "We need a bit more information to create your local transaction."

    fill_in 'Lgsl code', :with => '1'
    click_button 'Create Local transaction'
    assert page.has_content? "Viewing “Foo bar” Edition 1"
  end

  test "editing a local transaction has the LGSL and LGIL fields" do
    edition = FactoryGirl.create(:local_transaction_edition, :panopticon_id => @artefact.id, :slug => @artefact.slug,
                                 :title => "Foo transaction", :lgsl_code => 1)

    visit "/editions/#{edition.to_param}"
    assert page.has_content? "Viewing “Foo transaction” Edition 1"

    # For some reason capybara was having trouble matching this disabled
    # field with the has_field? matcher. Retrieving it manually seems to
    # work.
    lgsl_element = page.find('#edition_lgsl_code')
    assert_equal '1', lgsl_element['value']
    assert page.has_field?("LGIL override", :with => "")

    fill_in "LGIL override", :with => '7'

    save_edition

    assert page.has_content? "Local transaction edition was successfully updated."

    e = LocalTransactionEdition.find(edition.id)
    assert_equal 7, e.lgil_override

    # Ensure it gets set to nil when clearing field
    fill_in "LGIL override", :with => ''
    save_edition

    assert page.has_content? "Local transaction edition was successfully updated."

    e = LocalTransactionEdition.find(edition.id)
    assert_equal nil, e.lgil_override
  end

  test "editing a local transaction with an error" do
    edition = FactoryGirl.create(:local_transaction_edition,
      :panopticon_id => @artefact.id,
      :slug => @artefact.slug,
      :title => "Foo transaction",
      :lgsl_code => 1
    )

    visit "/editions/#{edition.to_param}"

    fill_in "Title", :with => ""
    save_edition

    assert page.has_content? "We had some problems saving"
  end
end
