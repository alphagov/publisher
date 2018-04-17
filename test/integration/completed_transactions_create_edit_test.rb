#encoding: utf-8
require 'integration_test_helper'

class CompletedTransactionCreateEditTest < JavascriptIntegrationTest
  setup do
    @artefact = FactoryBot.create(:artefact,
        slug: "done/stick-a-fork-in-me-im",
        kind: "completed_transaction",
        name: "All bar done",
        owning_app: "publisher",
                                  )

    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
  end

  should "create a new CompletedTransactionEdition" do
    visit "/publications/#{@artefact.id}"

    assert page.has_content? 'All bar done #1'

    t = CompletedTransactionEdition.first
    assert_equal @artefact.id.to_s, t.panopticon_id
  end

  with_and_without_javascript do
    should "allow editing CompletedTransactionEdition" do
      completed_transaction = FactoryBot.create(:completed_transaction_edition,
                                   panopticon_id: @artefact.id,
                                   title: "All bar done")

      visit_edition completed_transaction

      assert page.has_content? 'All bar done #1'
      assert page.has_field?("Title", with: "All bar done")
      fill_in "Title", with: "Changed title"

      save_edition_and_assert_success

      assert page.has_css?('.label', text: 'Draft')
      assert 'Changed title', completed_transaction.title
    end
  end

  should "allow creating a new version of a CompletedTransactionEdition" do
    completed_transaction = FactoryBot.create(:completed_transaction_edition,
                                 panopticon_id: @artefact.id,
                                 state: 'published',
                                 title: "All bar done")

    visit_edition completed_transaction

    click_on "Create new edition"

    assert page.has_content? 'All bar done #2'
  end

  should "disable fields for a published edition" do
    edition = FactoryBot.create(:completed_transaction_edition,
                                  panopticon_id: @artefact.id,
                                  state: 'published',
                                  title: "All bar done")

    visit_edition edition
    assert_all_edition_fields_disabled(page)
  end

  should "allow controlling display of promotions on this page" do
    edition = FactoryBot.create(:completed_transaction_edition, panopticon_id: @artefact.id)
    organ_donor_registration_promotion_url = "https://www.organdonation.nhs.uk/how_to_become_a_donor/registration/consent.asp?campaign=2244&v=7"

    visit_edition edition
    assert page.has_unchecked_field? "Promote organ donation"

    choose "Promote organ donation"
    fill_in "Promotion choice URL", with: organ_donor_registration_promotion_url
    save_edition_and_assert_success

    visit current_path # Refresh the page to check that the boxes are still ticked.
    assert page.has_checked_field? "Promote organ donation"
    assert page.has_field? 'Promotion choice URL', with: organ_donor_registration_promotion_url
  end

  should "only allow one promotion to be displayed at once" do
    edition = FactoryBot.create(:completed_transaction_edition, panopticon_id: @artefact.id)
    register_to_vote_promotion_url = "https://gov.uk/register-to-vote"

    visit_edition edition

    assert page.has_unchecked_field? "Promote register to vote"

    choose "Promote register to vote"
    fill_in "Promotion choice URL", with: register_to_vote_promotion_url
    save_edition_and_assert_success

    assert page.has_checked_field? "Promote register to vote"
    assert page.has_field? "Promotion choice URL", with: register_to_vote_promotion_url
    assert page.has_unchecked_field? "Promote organ donation"
  end

  should "show list of promotion options" do
    edition = FactoryBot.create(:completed_transaction_edition, panopticon_id: @artefact.id)

    visit_edition edition

    assert page.has_content? "Don't promote anything on this page"
    assert page.has_content? "Promote organ donation"
    assert page.has_content? "Promote register to vote"
    assert page.has_content? "Promote MOT Reminders"
  end
end
