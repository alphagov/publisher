#encoding: utf-8
require 'integration_test_helper'

class CompletedTransactionCreateEditTest < JavascriptIntegrationTest
  setup do
    @artefact = FactoryGirl.create(:artefact,
        slug: "done/stick-a-fork-in-me-im",
        kind: "completed_transaction",
        name: "All bar done",
        owning_app: "publisher",
    )

    setup_users
    stub_collections
  end

  should "create a new CompletedTransactionEdition" do
    visit "/publications/#{@artefact.id}"

    assert page.has_content? 'All bar done #1'

    t = CompletedTransactionEdition.first
    assert_equal @artefact.id.to_s, t.panopticon_id
  end

  with_and_without_javascript do
    should "allow editing CompletedTransactionEdition" do
      completed_transaction = FactoryGirl.create(:completed_transaction_edition,
                                   :panopticon_id => @artefact.id,
                                   :title => "All bar done")

      visit "/editions/#{completed_transaction.to_param}"

      assert page.has_content? 'All bar done #1'
      assert page.has_field?("Title", :with => "All bar done")
      fill_in "Title", :with => "Changed title"

      save_edition_and_assert_success

      assert page.has_css?('.label', text: 'Draft')
      assert 'Changed title', completed_transaction.title
    end
  end

  should "allow creating a new version of a CompletedTransactionEdition" do
    completed_transaction = FactoryGirl.create(:completed_transaction_edition,
                                 :panopticon_id => @artefact.id,
                                 :state => 'published',
                                 :title => "All bar done")

    visit "/editions/#{completed_transaction.to_param}"

    click_on "Create new edition"

    assert page.has_content? 'All bar done #2'

  end

  should "disable fields for a published edition" do
    edition = FactoryGirl.create(:completed_transaction_edition,
                                  :panopticon_id => @artefact.id,
                                  :state => 'published',
                                  :title => "All bar done")

    visit "/editions/#{edition.to_param}"
    assert_all_edition_fields_disabled(page)
  end
end
