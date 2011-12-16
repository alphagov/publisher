require 'test_helper'

class PublicationsControllerTest < ActionController::TestCase
  test "returns a 404 if the publication isn't found" do
    Publication.expects(:find_and_identify_edition).returns(nil)
    get :show, :id => 'fake-slug', :format => :json
    assert_response :not_found
  end
end
