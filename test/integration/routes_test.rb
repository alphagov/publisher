require "integration_test_helper"

class RoutesTest < ActionDispatch::IntegrationTest
  should "route to new reports controller when 'design_system_reports_page' toggle is enabled" do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_reports_page, true)

    assert_routing("/reports", controller: "reports", action: "index")
  end

  should "route to legacy reports controller when 'design_system_reports_page' toggle is disabled" do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_reports_page, false)

    assert_routing("/reports", controller: "legacy_reports", action: "index")
  end

  should "route to legacy reports controller when 'design_system_downtime_edit' toggle is enabled" do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_downtime_edit, true)
    edition = FactoryBot.create(:edition)
    edition_id = edition.id.to_s

    assert_routing("/editions/#{edition_id}/downtime/edit", controller: "downtimes", action: "edit", edition_id:)
  end

  should "route to new downtimes controller when 'design_system_downtime_new' toggle is enabled" do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_downtime_new, true)

    assert_routing("/editions/1/downtime/new", controller: "downtimes", action: "new", edition_id: "1")
  end

  should "route to legacy downtimes controller when 'design_system_downtime_new' toggle is disabled" do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_downtime_new, false)

    assert_routing("/editions/1/downtime/new", controller: "legacy_downtimes", action: "new", edition_id: "1")
  end

  should "route to new downtimes controller index action when 'design_system_downtime_index_page' toggle is enabled" do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_downtime_index_page, true)

    assert_routing("/downtimes", controller: "downtimes", action: "index")
  end

  should "route to legacy downtimes controller index action when 'design_system_downtime_index_page' toggle is disabled" do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_downtime_index_page, false)

    assert_routing("/downtimes", controller: "legacy_downtimes", action: "index")
  end
end
