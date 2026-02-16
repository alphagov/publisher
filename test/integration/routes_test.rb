require "legacy_integration_test_helper"

class RoutesTest < LegacyIntegrationTest
  should "route to downtimes controller for edit downtime" do
    edition = FactoryBot.create(:edition)
    edition_id = edition.id.to_s

    assert_routing("/editions/#{edition_id}/downtime/edit", controller: "downtimes", action: "edit", edition_id:)
  end

  should "route to new downtimes controller new downtime" do
    assert_routing("/editions/1/downtime/new", controller: "downtimes", action: "new", edition_id: "1")
  end

  context "new design system" do
    context "migrated design system content types" do
      %i[answer_edition help_page_edition place_edition transaction_edition completed_transaction_edition local_transaction_edition guide_edition].each do |content_type|
        context content_type do
          setup do
            service = LocalService.create!(lgsl_code: 1, providing_tier: %w[county unitary])
            @edition = if content_type != :local_transaction_edition
                         FactoryBot.build(content_type)
                       else
                         FactoryBot.build(content_type, lgsl_code: service.lgsl_code, lgil_code: 1, panopticon_id: FactoryBot.create(:artefact).id)
                       end
            @edition.save!
          end

          should "route to editions controller" do
            assert_editions_controller
          end
        end
      end
    end

    context "un-migrated content types" do
      %i[simple_smart_answer_edition].each do |content_type|
        context content_type do
          setup do
            @edition = FactoryBot.build(content_type)
            @edition.save!
          end

          should "route to legacy editions controller" do
            assert_legacy_editions_controller
          end
        end
      end
    end

    context "when the 'design_system_phase_4' feature toggle is on" do
      setup do
        @test_strategy.switch!(:design_system_edit_phase_4, true)
      end

      should "route to artefacts controller" do
        assert_routing("/artefacts/new", controller: "artefacts", action: "new")
        assert_routing({ method: "post", path: "/artefacts/new/content-details" }, controller: "artefacts", action: "content_details")
        assert_routing({ method: "post", path: "/artefacts" }, controller: "artefacts", action: "create")
      end

      should "route update to legacy_artefacts controller" do
        edition = FactoryBot.create(:edition)
        assert_routing({ method: "patch", path: "/artefacts/#{edition.id}" }, controller: "legacy_artefacts", action: "update", id: edition.id)
      end
    end

    context "when the 'design_system_phase_4' feature toggle is off" do
      setup do
        @test_strategy.switch!(:design_system_edit_phase_4, false)
      end

      should "route to legacy_artefacts controller" do
        edition = FactoryBot.create(:edition)

        assert_routing("/artefacts/new", controller: "legacy_artefacts", action: "new")
        assert_routing({ method: "post", path: "/artefacts" }, controller: "legacy_artefacts", action: "create")
        assert_routing({ method: "patch", path: "/artefacts/#{edition.id}" }, controller: "legacy_artefacts", action: "update", id: edition.id)
      end
    end
  end

  def assert_editions_controller
    assert_routing("/editions/#{@edition.id}", controller: "editions", action: "show", id: @edition.id.to_s)
  end

  def assert_legacy_editions_controller
    assert_routing("/editions/#{@edition.id}", controller: "legacy_editions", action: "show", id: @edition.id.to_s)
  end
end
