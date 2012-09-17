require 'test_helper'

class BusinessSupportImporterTest < ActiveSupport::TestCase
  
  def setup
    @user = FactoryGirl.create(:user, :name => "Test user")
    @artefact = FactoryGirl.create(:artefact, slug: "licence-to-test",
      kind: "licence", name: "test", owning_app: "publisher")
    
    response = mock()
    response.stubs(:code).returns(201)
    response.stubs(:to_hash).returns({ 'id' => @artefact.id })
    
    GdsApi::Panopticon.any_instance.stubs(:create_artefact).returns(response)
    
    @importer = BusinessSupportImporter.new("data/foo", @user.name)
    @row = CSV::Row.new(['title', 'long_description'], 
      ['Supporting business', '<p><strong>Software testing</strong> can be stated as the process of <em>validating</em> and verifying a product.</p>'])
  end
  
  def test_import
    silence_stream(STDOUT) do
      @importer.import(@row)
    end
    @imported = BusinessSupportEdition.last
    assert_equal 'supporting-business', @imported.slug
    assert_equal 'supporting-business', @imported.business_support_identifier
    assert_equal @artefact.id.to_s, @imported.panopticon_id 
  end
  
  def test_marked_down
    assert_equal "**strong**", @importer.marked_down("<strong>strong</strong>")
    assert_equal "**strong**", @importer.marked_down("&lt;strong&gt;strong&lt;/strong&gt;", true)
  end
  
end
