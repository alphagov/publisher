require "integration_test_helper"

class RoutesTest < PublisherIntegrationTest
  should "route to downtimes controller for edit downtime" do
    edition = FactoryBot.create(:edition)
    edition_id = edition.id.to_s

    assert_routing("/editions/#{edition_id}/downtime/edit", controller: "downtimes", action: "edit", edition_id:)
  end

  should "route to new downtimes controller new downtime" do
    assert_routing("/editions/1/downtime/new", controller: "downtimes", action: "new", edition_id: "1")
  end
end
