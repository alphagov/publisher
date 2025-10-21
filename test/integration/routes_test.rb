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
    setup do
      @test_strategy = Flipflop::FeatureSet.current.test!
    end

    context "non-legacy (old phase 1) content types" do
      %i[answer_edition help_page_edition].each do |content_type|
        context content_type do
          setup do
            @edition = FactoryBot.create(content_type)
          end

          should "route to editions controller" do
            @test_strategy.switch!(:design_system_edit_phase_2, false)
            @test_strategy.switch!(:design_system_edit_phase_3a, false)

            assert_editions_controller
          end
        end
      end
    end

    context "phase 2 content types" do
      %i[place_edition transaction_edition completed_transaction_edition local_transaction_edition].each do |content_type|
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

          should "route to editions controller with phase 2 enabled" do
            @test_strategy.switch!(:design_system_edit_phase_2, true)
            @test_strategy.switch!(:design_system_edit_phase_3a, false)

            assert_editions_controller
          end

          should "route to legacy editions controller with phase 2 disabled" do
            @test_strategy.switch!(:design_system_edit_phase_2, false)
            @test_strategy.switch!(:design_system_edit_phase_3a, false)

            assert_legacy_editions_controller
          end
        end
      end
    end

    context "phase 3a content types" do
      %i[guide_edition].each do |content_type|
        context content_type do
          setup do
            @edition = FactoryBot.create(content_type)
          end

          should "route to editions controller with phase 3a enabled" do
            @test_strategy.switch!(:design_system_edit_phase_2, false)
            @test_strategy.switch!(:design_system_edit_phase_3a, true)

            assert_editions_controller
          end

          should "route to legacy editions controller with phase 3a disabled" do
            @test_strategy.switch!(:design_system_edit_phase_2, false)
            @test_strategy.switch!(:design_system_edit_phase_3a, false)

            assert_legacy_editions_controller
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

            @test_strategy.switch!(:design_system_edit_phase_2, true)
            @test_strategy.switch!(:design_system_edit_phase_3a, true)
          end

          should "route to legacy editions controller" do
            assert_legacy_editions_controller
          end
        end
      end
    end

    teardown do
      @test_strategy.switch!(:design_system_edit_phase_2, false)
      @test_strategy.switch!(:design_system_edit_phase_3a, false)
    end
  end

  def assert_editions_controller
    assert_routing("/editions/#{@edition.id}", controller: "editions", action: "show", id: @edition.id.to_s)
  end

  def assert_legacy_editions_controller
    assert_routing("/editions/#{@edition.id}", controller: "legacy_editions", action: "show", id: @edition.id.to_s)
  end
end
