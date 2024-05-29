require "integration_test_helper"

class RoutesTest < ActionDispatch::IntegrationTest
  should "route to downtimes controller when 'design_system_downtime_edit' toggle is enabled" do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_downtime_edit, true)
    edition = FactoryBot.create(:edition)
    edition_id = edition.id.to_s

    assert_routing("/editions/#{edition_id}/downtime/edit", controller: "downtimes", action: "edit", edition_id:)
  end

  should "route to legacy downtimes controller when 'design_system_downtime_edit' toggle is disabled" do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_downtime_edit, false)
    edition = FactoryBot.create(:edition)
    edition_id = edition.id.to_s

    assert_routing("/editions/#{edition_id}/downtime/edit", controller: "legacy_downtimes", action: "edit", edition_id:)
  end

  should "route to new downtimes controller" do
    assert_routing("/editions/1/downtime/new", controller: "downtimes", action: "new", edition_id: "1")
  end
end
