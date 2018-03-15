require 'test_helper'

class LicenceContentImporterTest < ActiveSupport::TestCase
  def setup
    @user = FactoryBot.create(:user, name: "Test user")
    @artefact = FactoryBot.create(:artefact, slug: "licence-to-test",
      kind: "licence", name: "test", owning_app: "publisher")

    @importer = LicenceContentImporter.new('data/foo', @user.name)
    @row = CSV::Row.new(%w(OID NAME LONGDESC),
      [12345, 'Licence to test', '<p><strong>Software testing</strong> can be stated as the process of <em>validating</em> and verifying a product.</p>'])
  end

  def test_report
    @importer.report(@row)
    assert_equal "12345", @importer.imported.first[:identifier]
    assert_equal 'licence-to-test', @importer.imported.first[:slug]
    assert_match(
      /\*\*Software testing\*\*/,
      @importer.imported.first[:description]
    )
    assert_match(/\_validating\_/, @importer.imported.first[:description])
  end

  def test_import
    @importer.import(@row)
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
