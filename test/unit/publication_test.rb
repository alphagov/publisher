require 'test_helper'

class PublicationTest < ActiveSupport::TestCase
  test "when another validation error occurs we should not claim a slug" do
    PanopticonApi.any_instance.stubs(:save).returns(true)
    PanopticonApi.expects(:new).never
    g = Guide.new
    g.save
    assert ! g.errors['slug'].empty?
  end
  
  test "when slug is a duplicate for another publication it should not talk to panopticon" do
    PanopticonApi.any_instance.stubs(:save).returns(true)
    PanopticonApi.any_instance.expects(:save).once.returns(true)
    g = Guide.new(:name => 'My Test Guide', :slug => 'my-test-guide')
    assert g.save
    
    g2 = Guide.new(:name => 'My Test Guide', :slug => 'my-test-guide')
    assert ! g2.save
    assert_equal 'is already taken', g2.errors['slug'].first
  end
  
  test "when panopticon says a slug is available (and claims it) validation should pass" do
    PanopticonApi.any_instance.expects(:save).returns(true)
    g = Guide.new(:name => 'My Test Guide', :slug => 'my-test-guide')
    assert g.save
    assert g.errors['slug'].blank?
  end
    
  test "when panopticon says a slug is taken validation should fail" do
    stub_request(:post, "panopticon.dev.gov.uk/slugs").to_return(:status => 409)
    g = Guide.new(:name => 'My Test Guide', :slug => 'my-test-guide')
    assert ! g.save
    assert g.errors['slug'].any?
  end

  test "when a publication is deleted its slug should be released" do
    PanopticonApi.any_instance.stubs(:save).returns(true)
    PanopticonApi.any_instance.expects(:destroy).returns(true)
    
    g = Guide.new(:name => 'Another Test Guide', :slug => 'another-test-guide')
    assert g.save
    assert g.destroy
  end
end
