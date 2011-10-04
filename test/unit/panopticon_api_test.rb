require 'test_helper'

class PanopticonApiTest < ActiveSupport::TestCase
  test "it doesn't try to save a new slug if parameters are missing" do
    a = PanopticonApi.new(:slug => 'james')
    assert ! a.save
    assert a.errors[:kind].any?
    assert a.errors[:owning_app].any?
  end
  
  test "when saving, it registers an error on the object if the slug is already taken" do
    stub_request(:post, "panopticon.dev.gov.uk/slugs").to_return(:status => 409)
    a = PanopticonApi.new(:slug => 'james', :kind => 'answer', :owning_app => 'publisher')
    assert ! a.save
    assert_equal "must be unique across Gov.UK", a.errors[:base].first
  end
  
  test "when saving, it registers an error on the object if the slug is already taken (using the old API)" do
    stub_request(:post, "panopticon.dev.gov.uk/slugs").to_return(:status => 406)
    a = PanopticonApi.new(:slug => 'james', :kind => 'answer', :owning_app => 'publisher')
    assert ! a.save
    assert_equal "must be unique across Gov.UK", a.errors[:base].first
  end
  

  test "save returns true once the slug is claimed" do
    stub_request(:post, "panopticon.dev.gov.uk/slugs").to_return(:status => 201)
    a = PanopticonApi.new(:slug => 'james', :kind => 'answer', :owning_app => 'publisher')
    assert a.save
  end
  
  test "find returns a hash with slug details" do
    stub_request(:get, "panopticon.dev.gov.uk/slugs/james").to_return(:status => 200, :body => "{\"slug\":\"james\",\"owning_app\":\"publisher\",\"kind\":\"answer\"}")
    a = PanopticonApi.find('james')
    assert_equal "answer", a['kind']
  end
  
  test "find returns false where the slug isn't found" do
    stub_request(:get, "panopticon.dev.gov.uk/slugs/james").to_return(:status => 404)
    assert ! PanopticonApi.find('james')
  end
  
  test "destroy returns true if the slug has been released" do
    stub_request(:delete, "http://http//panopticon.dev.gov.uk:80/slugs/james")
    stub_request(:delete, "panopticon.dev.gov.uk/slugs/james").to_return(:status => 200)
    a = PanopticonApi.new(:slug => 'james')
    assert a.destroy
  end
  
  test "destroy returns false if the slug failed to release" do
    stub_request(:delete, "panopticon.dev.gov.uk/slugs/james").to_return(:status => 304)
    a = PanopticonApi.new(:slug => 'james')
    assert ! a.destroy
  end
end
