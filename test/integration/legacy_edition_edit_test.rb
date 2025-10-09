# frozen_string_literal: true

require "legacy_integration_test_helper"

class LegacyEditionEditTest < LegacyIntegrationTest
  setup do
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
    stub_events_for_all_content_ids
    stub_users_from_signon_api
    UpdateWorker.stubs(:perform_async)

    @test_strategy = Flipflop::FeatureSet.current.test!
    @test_strategy.switch!(:design_system_edit_phase_1, false)
    @test_strategy.switch!(:design_system_edit_phase_2, false)
    @test_strategy.switch!(:design_system_edit_phase_3a, false)
  end

  context "content block guidance" do
    context "when show_link_to_content_block_manager? is false" do
      setup do
        @test_strategy.switch!(:show_link_to_content_block_manager, false)
        visit_draft_edition
      end

      should "not show the content block guidance" do
        assert_not page.has_text?("Content block")
      end
    end

    context "when show_link_to_content_block_manager? is true" do
      setup do
        @test_strategy.switch!(:show_link_to_content_block_manager, true)
        visit_draft_edition
      end

      should "show the content block guidance" do
        assert page.has_text?("Content block")
      end
    end
  end

  def create_draft_edition
    @draft_edition = FactoryBot.create(:edition, title: "Edit page title", state: "draft", overview: "metatags", in_beta: 1, body: "The body")
  end

  def visit_draft_edition
    create_draft_edition
    visit edition_path(@draft_edition)
  end
end
