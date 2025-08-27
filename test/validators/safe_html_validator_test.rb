require "test_helper"

class SafeHtmlTest < ActiveSupport::TestCase
  should "validate content's body" do
    edition = FactoryBot.build(:edition, body: "<script>")

    assert edition.invalid?
    assert_includes edition.errors.attribute_names, :body
  end

  context "what to validate" do
    should "allow clean content in nested fields" do
      edition = FactoryBot.build(:edition, body: { "clean" => ["plain text"] })
      assert edition.valid?
    end

    should "disallow images not hosted by us" do
      edition = FactoryBot.build(:edition, body: '<img src="http://evil.com/trollface"/>')

      assert edition.invalid?
      assert_includes edition.errors.attribute_names, :body
    end

    should "allow images hosted by us" do
      edition = FactoryBot.build(:edition, body: '<img src="http://www.dev.gov.uk/trollface"/>')

      assert edition.valid?
    end

    should "allow plain text" do
      edition = FactoryBot.build(:edition, body: "foo bar")

      assert edition.valid?
    end

    should "check only specified fields as Govspeak" do
      nasty_govspeak = '[Numberwang](script:nasty(); "Wangernum")'
      assert_not Govspeak::Document.new(nasty_govspeak).valid?, "expected this to be identified as bad"

      edition = FactoryBot.build(:edition, body: nasty_govspeak)

      assert edition.invalid?
    end

    should "all models that have govspeak fields should use this validator" do
      models_dir = File.expand_path("../../app/models/*", File.dirname(__FILE__))

      Dir[models_dir]
        .map { |file| File.basename(file, ".rb").camelize.constantize }
        .select { |klass| klass.const_defined?(:GOVSPEAK_FIELDS) }
        .each { |klass| assert_includes klass.validators.map(&:class), SafeHtml, "#{klass} must be validated with SafeHtml" }
    end
  end
end
