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
      @test_strategy.switch!(:design_system_edit, true)
    end

    context "allowed content types" do
      %i[answer_edition help_page_edition place_edition transaction_edition completed_transaction_edition].each do |content_type|
        context content_type do
          setup do
            @edition = FactoryBot.create(content_type)
          end

          should "route to editions controller" do
            assert_routing("/editions/#{@edition.id}", controller: "editions", action: "show", id: @edition.id.to_s)
          end
        end
      end
    end

    context "not allowed content types" do
      %i[guide_edition local_transaction_edition simple_smart_answer_edition].each do |content_type|
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

          should "route to legacy editions controller" do
            assert_routing("/editions/#{@edition.id}", controller: "legacy_editions", action: "show", id: @edition.id.to_s)
          end
        end
      end
    end

    teardown do
      @test_strategy.switch!(:design_system_edit, false)
    end
  end
end
