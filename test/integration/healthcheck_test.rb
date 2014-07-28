require 'integration_test_helper'

class HealthcheckTest < ActionDispatch::IntegrationTest
  test "returns health check status" do
    get "/healthcheck"
    assert_response :success
    assert JSON.parse(response.body)
  end
end
