require "legacy_integration_test_helper"

class UnpublishTest < LegacyIntegrationTest
  setup do
    @artefact = FactoryBot.create(
      :artefact,
      slug: "bertie-botts-every-flavour-beans",
      kind: "answer",
      name: "Bertie Bott's Every Flavour Beans",
      owning_app: "publisher",
    )

    @edition = FactoryBot.create(
      :simple_smart_answer_edition,
      panopticon_id: @artefact.id,
      body: "They're quite gross.",
    )
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
    stub_events_for_all_content_ids
    stub_users_from_signon_api

    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_publications_filter, false)
    test_strategy.switch!(:design_system_edit_phase_3a, false)
  end

  should "unpublishing an artefact archives all editions" do
    visit_edition @edition

    select_tab "Unpublish"

    UnpublishService.expects(:call).with(@artefact, User.first, "").returns(true)

    click_button "Unpublish"

    assert current_url, root_path

    within(".alert-success") do
      assert page.has_content?("Content unpublished")
    end

    @artefact.update!(state: "archived")

    visit_edition @edition

    within(".callout-danger") do
      assert page.has_content?("You can’t edit this publication")
      assert page.has_content?("All editions have been archived.")
    end
  end

  context "when redirecting a piece of content" do
    should "display a confirmation message when redirected successfully" do
      visit "editions/#{@edition.id}"

      select_tab "Unpublish"

      fill_in "redirect_url", with: "https://gov.uk/beans"

      UnpublishService.expects(:call).with(@artefact, User.first, "/beans").returns(true)

      click_button "Unpublish"

      assert current_url, root_path

      within(".alert-success") do
        assert page.has_content?("Content unpublished and redirected")
      end
    end
  end

  context "Welsh editors" do
    setup do
      @welsh_edition = FactoryBot.create(:guide_edition, :ready, :welsh)
      @welsh_editor = FactoryBot.create(:user, :welsh_editor)
      login_as(@welsh_editor)
    end

    should "not be able to see the unpublish tab for Welsh Editions" do
      visit_edition @welsh_edition

      assert_not page.has_css?(".nav.nav-tabs li", text: "Unpublish")
    end

    should "not be able to see the unpublish tab for non-Welsh Editions" do
      visit_edition @edition

      assert_not page.has_css?(".nav.nav-tabs li", text: "Unpublish")
    end
  end
end
