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
    @row = CSV::Row.new(['id', 'title', 'short_description', 'long_description', 'max_employees', 
       'min_grant_value', 'max_grant_value', 'organiser', 'contact_details', 'additional_information', 
       'eligibility', 'evaluation'], 
      [123, 'Supporting business', 'This description is short',
       '<p><strong>Software testing</strong> can be stated as the process of <em>validating</em> and verifying a product.</p>',
       '2000', '20', '50', 'Business support corp.', 'The Street, Townsville, 08223 347534', 'this is <em>additional info</em>',
       'To qualify you need to employ several cats.', 'All cats will need to pass compulsory basic training.'])
  end
  
  def test_import
    silence_stream(STDOUT) do
      @importer.import(@row)
    end
    @imported = BusinessSupportEdition.last
    assert_equal 'supporting-business', @imported.slug
    assert_equal '123', @imported.business_support_identifier
    assert_equal @artefact.id.to_s, @imported.panopticon_id
    assert_match 'This description is short', @imported.short_description
    assert_match '**Software testing**', @imported.body
    assert_match 'process of*validating*and verifying', @imported.body
    assert_equal 2000, @imported.max_employees
    assert_equal 20, @imported.min_value
    assert_equal 50, @imported.max_value
    assert_equal 'Business support corp.', @imported.organiser
    assert_equal 'The Street, Townsville, 08223 347534', @imported.contact_details
    assert_match 'this is*additional info*', @imported.additional_information
    assert_match 'To qualify you need to employ several cats.', @imported.eligibility
    assert_match 'All cats will need to pass compulsory basic training.', @imported.evaluation
  end
  
  def test_marked_down
    assert_equal "**strong**", @importer.marked_down("<strong>strong</strong>")
    assert_equal "**strong**", @importer.marked_down("&lt;strong&gt;strong&lt;/strong&gt;", true)
  end
  
  def test_valid_markdown_for_lists
    content = "<p>This is a list:</p><ul><li>One</li><li>two</li><li>three</li></ul>"
    markdown = "This is a list:

- One
- two
- three"

    assert_equal markdown, @importer.marked_down(content).strip
  end
  
end
