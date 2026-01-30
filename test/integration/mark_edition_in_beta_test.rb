require "legacy_integration_test_helper"

class MarkEditionInBetaTest < LegacyJavascriptIntegrationTest
  setup do
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
    stub_events_for_all_content_ids
    stub_users_from_signon_api
    UpdateWorker.stubs(:perform_async)
  end

  with_and_without_javascript do
    should "allow marking an edition as in beta" do
      edition = FactoryBot.create(:simple_smart_answer_edition)
      visit_edition edition

      assert_not find("#edition_in_beta").checked?
      check "Content is in beta"
      save_edition

      assert page.has_text? "Simple smart answer edition was successfully updated."
      assert find("#edition_in_beta").checked?

      visit "/?user_filter=all"
      assert page.has_text?("#{edition.title} beta")
    end

    should "allow marking an edition as not in beta" do
      edition = FactoryBot.create(:simple_smart_answer_edition, in_beta: true)
      visit_edition edition

      assert find("#edition_in_beta").checked?
      uncheck "Content is in beta"
      save_edition

      assert page.has_text? "Simple smart answer edition was successfully updated."
      assert_not find("#edition_in_beta").checked?

      visit "/?user_filter=all"
      assert page.has_no_text?("#{edition.title} beta")
    end
  end
end
