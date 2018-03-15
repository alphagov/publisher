require 'integration_test_helper'

class MarkEditionInBetaTest < JavascriptIntegrationTest
  setup do
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
  end

  with_and_without_javascript do
    should "allow marking an edition as in beta" do
      edition = FactoryBot.create(:edition)
      visit_edition edition

      refute find('#edition_in_beta').checked?
      check 'Content is in beta'

      save_edition_and_assert_success

      assert find('#edition_in_beta').checked?

      visit "/?user_filter=all"
      assert page.has_text?("#{edition.title} beta")
    end

    should "allow marking an edition as not in beta" do
      edition = FactoryBot.create(:edition, in_beta: true)
      visit_edition edition

      assert find('#edition_in_beta').checked?
      uncheck 'Content is in beta'

      save_edition_and_assert_success

      refute find('#edition_in_beta').checked?

      visit "/?user_filter=all"
      refute page.has_text?("#{edition.title} beta")
    end
  end
end
