require 'test_helper'

require 'api/generator'

class GeneratorTest < ActiveSupport::TestCase
  setup do
    @edition = Guide.new.editions.first
  end

  test "correctly picks a generator class given an edition" do
    assert_equal Api::Generator::Guide, Api::Generator.generator_class(@edition)
  end

  test "invokes edition_to_hash correctly" do
    Api::Generator::Guide.expects(:edition_to_hash).with(@edition)

    Api::Generator.edition_to_hash(@edition)
  end

  test "invokes edition_to_hash correctly when given extra args" do
    Api::Generator::Guide.expects(:edition_to_hash).with(@edition, 'arg1', :arg2)

      Api::Generator.edition_to_hash(@edition, 'arg1', :arg2)
  end
end