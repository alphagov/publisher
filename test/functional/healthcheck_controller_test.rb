require 'test_helper'

class HealthcheckControllerTest < ActionController::TestCase

  def json
    JSON.parse(response.body)
  end

  test "it returns a 200 response" do
    get :check, format: :json
    assert_response :success
  end

  test "it returns an overall status field" do
    get :check, format: :json
    assert json.has_key? "status"
  end
end
