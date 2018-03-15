#encoding: utf-8
require 'integration_test_helper'

class HelpPageCreateEditTest < JavascriptIntegrationTest
  setup do
    @artefact = FactoryBot.create(:artefact,
        slug: "help/hedgehog-topiary",
        kind: "help_page",
        name: "Foo bar",
        owning_app: "publisher",
                                  )

    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
  end

  should "create a new HelpPageEdition" do
    visit "/publications/#{@artefact.id}"

    assert page.has_content? 'Foo bar #1'

    h = HelpPageEdition.first
    assert_equal @artefact.id.to_s, h.panopticon_id
  end

  with_and_without_javascript do
    should "allow editing HelpPageEdition" do
      help_page = FactoryBot.create(:help_page_edition,
                                     panopticon_id: @artefact.id,
                                     title: "Foo bar",
                                     body: "Body content")
      visit_edition help_page

      assert page.has_content? 'Foo bar #1'
      assert page.has_field?("Title", with: "Foo bar")
      assert page.has_field?("Body", with: "Body content")

      fill_in "Body", with: "This body has changed"
      fill_in "Title", with: "This title has changed"
      save_edition_and_assert_success

      h = HelpPageEdition.find(help_page.id)
      assert_equal "This body has changed", h.body
      assert_equal "This title has changed", h.title
    end

    should "allow creating a new version of a HelpPageEdition" do
      help_page = FactoryBot.create(:help_page_edition,
                                   panopticon_id: @artefact.id,
                                   state: 'published',
                                   title: "Foo bar",
                                   body: "This is really helpful")

      visit_edition help_page
      click_on "Create new edition"

      assert page.has_content? 'Foo bar #2'
      assert page.has_field?("Body", with: "This is really helpful")
    end
  end

  should "disable fields for a published edition" do
    edition = FactoryBot.create(:help_page_edition,
                                 panopticon_id: @artefact.id,
                                 state: 'published',
                                 title: "Foo bar",
                                 body: "This is really helpful")

    visit_edition edition
    assert_all_edition_fields_disabled(page)
  end
end
