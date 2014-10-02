require 'test_helper'

class HealthcheckControllerTest < ActionController::TestCase

  def json
    JSON.parse(response.body)
  end

  context "response structure" do
    setup do
      Edition.stubs(:scheduled_for_publishing).returns(stub(count: 0))
      ScheduledPublisher.stubs(:queue_size).returns(0)
    end

    should "return a 200 response" do
      get :check
      assert_response :success
    end

    should "return an overall status field" do
      get :check
      assert_includes json, "status"
    end

    should "have a field for the checks" do
      get :check
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
      get :check
      assert_includes json["checks"], "schedule_queue"
      assert_equal "ok", json["checks"]["schedule_queue"]["status"]
    end

    should "report the overall status as ok" do
      get :check
      assert_equal "ok", json["status"]
    end

    should "include a status message" do
      get :check, format: :json
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
      get :check
      assert_includes json["checks"], "schedule_queue"
      assert_equal "warning", json["checks"]["schedule_queue"]["status"]
    end

    should "include a status message" do
      get :check
      assert_includes json["checks"], "schedule_queue"
      assert_equal(
        "5 scheduled edition(s); 3 item(s) queued",
        json["checks"]["schedule_queue"]["message"]
      )
    end

    should "report the overall status as a warning" do
      get :check
      assert_equal "warning", json["status"]
    end
  end

  context "cannot connect to the Mongo" do
    setup do
      Edition.stubs(:scheduled_for_publishing).raises(Mongo::ConnectionFailure)
      ScheduledPublisher.stubs(:queue_size).returns(3)
    end

    should "report a critical error" do
      get :check

      assert_equal "critical", json["checks"]["schedule_queue"]["status"]
    end
  end

  context "Mongo connection fails" do
    # Yes, the Mongo driver has two separate exceptions for connection failure.
    # No, they don't have a common parent below StandardError. I think
    # `ConnectionFailure` is when it can't connect, and `ConnectionError` is
    # when it loses connection, but I wouldn't swear to it.
    setup do
      Edition.stubs(:scheduled_for_publishing).raises(Mongo::ConnectionError)
      ScheduledPublisher.stubs(:queue_size).returns(3)
    end

    should "report a critical error" do
      get :check

      assert_equal "critical", json["checks"]["schedule_queue"]["status"]
    end
  end

  context "cannot connect to Redis" do
    setup do
      Edition.stubs(:scheduled_for_publishing).returns(stub(count: 5))
      ScheduledPublisher.stubs(:queue_size).raises(Redis::CannotConnectError)
    end

    should "report a critical error" do
      get :check

      assert_equal "critical", json["checks"]["schedule_queue"]["status"]
    end
  end
end
