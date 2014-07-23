require 'integration_test_helper'

class HealthcheckTest < ActionDispatch::IntegrationTest
  test "returns health check status" do
    get "/healthcheck", format: :json
    assert_response :success
    assert JSON.parse(response.body)
  end
end
