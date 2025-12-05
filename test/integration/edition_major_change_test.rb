require "legacy_integration_test_helper"

class EditionMajorChangeTest < LegacyJavascriptIntegrationTest
  setup do
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
    stub_events_for_all_content_ids
    stub_users_from_signon_api
    UpdateWorker.stubs(:perform_async)

    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_edit_phase_3a, false)
  end

  teardown do
    GDS::SSO.test_user = nil
  end

  test "doesn't show change note until an edition has been published" do
    edition = FactoryBot.create(:guide_edition)
    visit_edition edition
    assert page.has_no_field?("edition_change_note")
    assert page.has_no_field?("edition_major_change")
  end

  without_javascript do
    context "change note fields" do
      setup do
        @edition = FactoryBot.create(:guide_edition, state: "published")
      end

      should "show change note fields once an edition has been published" do
        visit_edition @edition
        assert page.has_field?("edition_change_note", disabled: true)
        assert page.has_field?("edition_major_change", disabled: true)
      end

      context "for an edition in a published series" do
        setup do
          @second_edition = @edition.build_clone
          @second_edition.save!
        end

        should "be visible" do
          visit_edition @second_edition
          assert page.has_field?("edition_change_note")
          assert page.has_field?("edition_major_change")
        end

        should "validate that the change note is present for a major change" do
          visit_edition @second_edition
          check("edition_major_change")
          save_edition_and_assert_error("can't be blank", "#edition_change_note")

          fill_in "edition_change_note", with: "Something changed"
          save_edition_and_assert_success
        end
      end
    end
  end
end
