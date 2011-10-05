require 'test_helper'

class PublicationsControllerTest < ActionController::TestCase
  test "when given a section it should return its details" do
    section_slug = Publication::SECTIONS.first.parameterize
    get :show, :id => section_slug, :format => :json
    assert_equal Publication::SECTIONS.first, JSON.parse(@response.body)['name']
  end
  
  test "when given an audience it should return its details" do
    section_slug = Publication::AUDIENCES.first.parameterize
    get :show, :id => section_slug, :format => :json
    assert_equal Publication::AUDIENCES.first, JSON.parse(@response.body)['name']
  end
end
