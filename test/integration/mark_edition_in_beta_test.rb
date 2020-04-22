require "integration_test_helper"

class MarkEditionInBetaTest < JavascriptIntegrationTest
  setup do
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
  end

  with_and_without_javascript do
    should "allow marking an edition as in alpha" do
      edition = FactoryBot.create(:edition)
      visit_edition edition

      select("alpha")

      save_edition_and_assert_success

      visit "/?user_filter=all"

      assert page.has_text?("alpha")
    end

    should "allow marking an edition as in beta" do
      edition = FactoryBot.create(:edition)
      visit_edition edition

      select("beta")

      save_edition_and_assert_success

      visit "/?user_filter=all"

      assert page.has_text?("beta")
    end

    should "allow marking an edition as live" do
      edition = FactoryBot.create(:edition, phase: "beta")
      visit_edition edition

      select("live")

      save_edition_and_assert_success

      visit "/?user_filter=all"

      assert page.has_text?(edition.title)
      assert page.has_no_text?("alpha")
      assert page.has_no_text?("beta")
    end
  end
end
