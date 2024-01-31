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
end
