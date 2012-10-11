require 'test_helper'

class LicenceContentImporterTest < ActiveSupport::TestCase

  def setup
    @user = FactoryGirl.create(:user, :name => "Test user")
    @artefact = FactoryGirl.create(:artefact, slug: "licence-to-test",
      kind: "licence", name: "test", owning_app: "publisher")

    response = mock()
    response.stubs(:code).returns(201)
    response.stubs(:to_hash).returns({ 'id' => @artefact.id })
    
    GdsApi::Panopticon.any_instance.stubs(:artefact_for_slug).with("licence-to-test").returns(response)
    GdsApi::Panopticon.any_instance.stubs(:create_artefact).returns(response)

    @importer = LicenceContentImporter.new('data/foo', @user.name)
    @row = CSV::Row.new(['OID', 'NAME', 'LONGDESC'],
      [12345, 'Licence to test', '<p><strong>Software testing</strong> can be stated as the process of <em>validating</em> and verifying a product.</p>'])
  end

  def test_report
    silence_stream(STDOUT) do
      @importer.report(@row)
    end
    assert_equal "12345", @importer.imported.first[:identifier]
    assert_equal 'licence-to-test', @importer.imported.first[:slug]
    assert_match /\*\*Software testing\*\*/, @importer.imported.first[:description]
    assert_match /\*validating\*/, @importer.imported.first[:description]
  end

  def test_import
    silence_stream(STDOUT) do
      @importer.import(@row)
    end
    assert 12345, @importer.imported.first.licence_identifier
    assert_equal 'licence-to-test', @importer.imported.first.slug
    assert_equal @artefact.id.to_s, @importer.imported.first.panopticon_id
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
