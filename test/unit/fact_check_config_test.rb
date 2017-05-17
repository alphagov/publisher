require 'test_helper'
require 'fact_check_config'

class FactCheckConfigTest < ActiveSupport::TestCase
  should "fail on a nil address format" do
    assert_raises ArgumentError do
      FactCheckConfig.new(nil)
    end
  end

  should "fail on an empty address format" do
    assert_raises ArgumentError do
      FactCheckConfig.new("")
    end
  end

  should "fail on an address format with no ID marker" do
    assert_raises ArgumentError do
      FactCheckConfig.new("factcheck@example.com")
    end
  end

  should "accept an address format with an ID marker" do
    FactCheckConfig.new("factcheck+{id}@example.com")
  end

  should "fail on an address format with multiple ID markers" do
    assert_raises ArgumentError do
      FactCheckConfig.new("factcheck+{id}+{id}@example.com")
    end
  end

  should "recognise a valid fact check address" do
    config = FactCheckConfig.new("factcheck+{id}@example.com")
    assert config.valid_address?("factcheck+123456@example.com")
  end

  should "not recognise an invalid fact check address" do
    config = FactCheckConfig.new("factcheck+{id}@example.com")
    refute config.valid_address?("not-factcheck@example.com")
  end

  should "not recognise a fact check address with an empty ID" do
    config = FactCheckConfig.new("factcheck+{id}@example.com")
    refute config.valid_address?("factcheck+@example.com")
  end

  should "extract an item ID from a valid address" do
    config = FactCheckConfig.new("factcheck+{id}@example.com")
    assert_equal "1234", config.item_id("factcheck+1234@example.com")
  end

  should "raise an exception trying to extract an ID from an invalid address" do
    config = FactCheckConfig.new("factcheck+{id}@example.com")
    assert_raises ArgumentError do
      config.item_id("not-factcheck+1234@example.com")
    end
  end

  should "construct an address from an item ID" do
    config = FactCheckConfig.new("factcheck+{id}@example.com")
    assert_equal "factcheck+1234@example.com", config.address("1234")
  end

  should "accept item IDs that aren't strings" do
    # For example, Mongo IDs, but let's not tie this test to Mongo
    config = FactCheckConfig.new("factcheck+{id}@example.com")
    assert_equal "factcheck+1234@example.com", config.address(1234)
  end
end
