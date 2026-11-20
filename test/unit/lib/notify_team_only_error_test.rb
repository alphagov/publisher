require "test_helper"

class NotifyTeamOnlyErrorTest < ActiveSupport::TestCase
  def bad_request_error(body)
    response = stub(code: 400, body:)
    Notifications::Client::BadRequestError.new(response)
  end

  def fact_check_manager_error(code: 502, notify_error: "One or more recipients not in GOV.UK Notify team.")
    GdsApi::HTTPErrorResponse.new(code, "message", { "errors" => { "notify_error" => notify_error } })
  end

  context "outside production" do
    setup { GovukEnvironment.stubs(:current).returns("integration") }

    should "match a Notify team-only BadRequestError" do
      assert NotifyTeamOnlyError.matches?(bad_request_error("Can't send to this recipient using a team-only API key"))
    end

    should "not match other Notify BadRequestErrors" do
      assert_not NotifyTeamOnlyError.matches?(bad_request_error("Missing personalisation: title"))
    end

    should "match a Fact Check Manager 502 reporting the team-only error" do
      assert NotifyTeamOnlyError.matches?(fact_check_manager_error)
    end

    should "not match a Fact Check Manager 502 for another Notify error" do
      assert_not NotifyTeamOnlyError.matches?(fact_check_manager_error(notify_error: "Missing personalisation: title"))
    end

    should "not match other Fact Check Manager errors" do
      assert_not NotifyTeamOnlyError.matches?(fact_check_manager_error(code: 422))
      assert_not NotifyTeamOnlyError.matches?(GdsApi::HTTPErrorResponse.new(502, "message"))
    end

    should "not match unrelated errors" do
      assert_not NotifyTeamOnlyError.matches?(StandardError.new("team-only API key"))
    end
  end

  context "in production" do
    setup { GovukEnvironment.stubs(:current).returns("production") }

    should "never match" do
      assert_not NotifyTeamOnlyError.matches?(bad_request_error("Can't send to this recipient using a team-only API key"))
      assert_not NotifyTeamOnlyError.matches?(fact_check_manager_error)
    end
  end
end
