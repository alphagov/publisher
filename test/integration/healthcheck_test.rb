require "legacy_integration_test_helper"

class HealthcheckTest < LegacyIntegrationTest
  def json
    JSON.parse(response.body)
  end

  context "scheduled count matches queue length" do
    setup do
      Edition.stubs(:scheduled_for_publishing).returns(stub(count: 0))
      ScheduledPublisher.stubs(:queue_size).returns(0)
    end

    should "report the check is ok" do
      get "/healthcheck/scheduled-publishing"
      assert_equal "ok", json["status"]
    end

    should "include a status message" do
      get "/healthcheck/scheduled-publishing"
      assert_equal(
        "0 scheduled edition(s); 0 item(s) queued",
        json["message"],
      )
    end
  end

  context "scheduled count does not match queue length" do
    setup do
      Edition.stubs(:scheduled_for_publishing).returns(stub(count: 5))
      ScheduledPublisher.stubs(:queue_size).returns(3)
    end

    should "report the check as a warning" do
      get "/healthcheck/scheduled-publishing"
      assert_equal "warning", json["status"]
    end

    should "include a status message" do
      get "/healthcheck/scheduled-publishing"
      assert_equal(
        "5 scheduled edition(s); 3 item(s) queued",
        json["message"],
      )
    end
  end
end
