require 'test_helper'

class HealthcheckTest < ActionDispatch::IntegrationTest
  def json
    JSON.parse(response.body)
  end

  context "response structure" do
    setup do
      Edition.stubs(:scheduled_for_publishing).returns(stub(count: 0))
      ScheduledPublisher.stubs(:queue_size).returns(0)
    end

    should "return a 200 response" do
      get "/healthcheck"
      assert_response :success
    end

    should "return an overall status field" do
      get "/healthcheck"
      assert_includes json, "status"
    end

    should "have a field for the checks" do
      get "/healthcheck"
      assert_includes json, "checks"
      assert json["checks"].is_a? Hash
    end
  end

  context "scheduled count matches queue length" do
    setup do
      Edition.stubs(:scheduled_for_publishing).returns(stub(count: 0))
      ScheduledPublisher.stubs(:queue_size).returns(0)
    end

    should "report the check is ok" do
      get "/healthcheck"
      assert_includes json["checks"], "schedule_queue"
      assert_equal "ok", json["checks"]["schedule_queue"]["status"]
    end

    should "report the overall status as ok" do
      get "/healthcheck"
      assert_equal "ok", json["status"]
    end

    should "include a status message" do
      get "/healthcheck"
      assert_includes json["checks"], "schedule_queue"
      assert_equal(
        "0 scheduled edition(s); 0 item(s) queued",
        json["checks"]["schedule_queue"]["message"]
      )
    end
  end

  context "scheduled count does not match queue length" do
    setup do
      Edition.stubs(:scheduled_for_publishing).returns(stub(count: 5))
      ScheduledPublisher.stubs(:queue_size).returns(3)
    end

    should "report the check as a warning" do
      get "/healthcheck"
      assert_includes json["checks"], "schedule_queue"
      assert_equal "warning", json["checks"]["schedule_queue"]["status"]
    end

    should "include a status message" do
      get "/healthcheck"
      assert_includes json["checks"], "schedule_queue"
      assert_equal(
        "5 scheduled edition(s); 3 item(s) queued",
        json["checks"]["schedule_queue"]["message"]
      )
    end

    should "report the overall status as a warning" do
      get "/healthcheck"
      assert_equal "warning", json["status"]
    end
  end
end
