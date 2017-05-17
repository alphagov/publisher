require 'integration_test_helper'

class LegacyRedirect < ActionDispatch::IntegrationTest
  should "redirect requests for the old index to the new one" do
    get "/admin"
    assert_response :redirect
    assert_redirected_to "/"
  end

  should "redirect requests for an old edition path to a new one" do
    get "/admin/editions/abcdefghijklmnop"
    assert_response :redirect
    assert_redirected_to "/editions/abcdefghijklmnop"
  end
end
