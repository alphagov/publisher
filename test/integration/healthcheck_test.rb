require "legacy_integration_test_helper"

class HealthcheckTest < LegacyIntegrationTest
  def json
    JSON.parse(response.body)
  end

  context "live check" do
    should "return a 200 OK when maintenance mode is implicitly disabled" do
      get "/healthcheck/live"
      assert_response :success
    end

    should "return a 200 OK when maintenance mode is explicitly disabled" do
      ClimateControl.modify MAINTENANCE_MODE: "false" do
        get "/healthcheck/live", env: { "MAINTENANCE_MODE" => "false" }
        assert_response :success
      end
    end

    should "return a 200 OK when maintenance mode is enabled" do
      ClimateControl.modify MAINTENANCE_MODE: "true" do
        get "/healthcheck/live"
        assert_response :success
      end
    end
  end

  context "ready check" do
    should "return a 200 OK when maintenance mode is implicitly disabled" do
      get "/healthcheck/ready"
      assert_response :success
    end

    should "return a 200 OK when maintenance mode is explicitly disabled" do
      ClimateControl.modify MAINTENANCE_MODE: "false" do
        get "/healthcheck/ready", env: { "MAINTENANCE_MODE" => "false" }
        assert_response :success
      end
    end

    should "return a 200 OK when maintenance mode is enabled" do
      ClimateControl.modify MAINTENANCE_MODE: "true" do
        get "/healthcheck/ready"
        assert_response :success
      end
    end
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
