require 'test_helper'

class SafeHtmlTest < ActiveSupport::TestCase
  class Dummy
    include Mongoid::Document

    field :i_am_govspeak, type: String

    GOVSPEAK_FIELDS = [:i_am_govspeak].freeze

    validates_with SafeHtml

    embeds_one :dummy_embedded_single, class_name: 'SafeHtmlTest::DummyEmbeddedSingle'
  end

  class DummyEmbeddedSingle
    include Mongoid::Document

    embedded_in :dummy, class_name: 'SafeHtmlTest::Dummy'

    field :i_am_govspeak, type: String

    GOVSPEAK_FIELDS = [:i_am_govspeak].freeze

    validates_with SafeHtml
  end

  context "we don't quite trust mongoid (2)" do
    should "validate embedded documents automatically" do
      embedded = DummyEmbeddedSingle.new(i_am_govspeak: "<script>")
      dummy = Dummy.new(i_am_govspeak: embedded)
      # Can't invoke embedded.valid? because that would run the validations
      assert dummy.invalid?
      assert_includes dummy.errors.keys, :i_am_govspeak
    end
  end

  context "what to validate" do
    should "allow clean content in nested fields" do
      dummy = Dummy.new(i_am_govspeak: { "clean" => ["plain text"] })
      assert dummy.valid?
    end

    should "disallow images not hosted by us" do
      dummy = Dummy.new(i_am_govspeak: '<img src="http://evil.com/trollface"/>')
      assert dummy.invalid?
      assert_includes dummy.errors.keys, :i_am_govspeak
    end

    should "allow images hosted by us" do
      dummy = Dummy.new(i_am_govspeak: '<img src="http://www.dev.gov.uk/trollface"/>')
      assert dummy.valid?
    end

    should "allow plain text" do
      dummy = Dummy.new(i_am_govspeak: "foo bar")
      assert dummy.valid?
    end

    should "check only specified fields as Govspeak" do
      nasty_govspeak = '[Numberwang](script:nasty(); "Wangernum")'
      assert ! Govspeak::Document.new(nasty_govspeak).valid?, "expected this to be identified as bad"

      dummy = Dummy.new(i_am_govspeak: nasty_govspeak)
      assert dummy.invalid?
    end

    should "all models that have govspeak fields should use this validator" do
      models_dir = File.expand_path("../../app/models/*", File.dirname(__FILE__))

      Dir[models_dir]
        .map { |file| File.basename(file, ".rb").camelize.constantize }
        .select { |klass| klass.included_modules.include?(Mongoid::Document) && klass.const_defined?(:GOVSPEAK_FIELDS) }
        .each { |klass| assert_includes klass.validators.map(&:class), SafeHtml, "#{klass} must be validated with SafeHtml" }
    end
  end
end
