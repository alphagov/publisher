require "test_helper"
require "fact_check_config"

class FactCheckConfigTest < ActiveSupport::TestCase
  should "fail on a nil address format" do
    assert_raises ArgumentError do
      FactCheckConfig.new(nil, "valid subject [{id}]")
    end
  end

  should "fail on an empty address format" do
    assert_raises ArgumentError do
      FactCheckConfig.new("", "valid subject [{id}]")
    end
  end

  should "fail on an address format with no ID marker" do
    assert_raises ArgumentError do
      FactCheckConfig.new("factcheck@example.com", "valid subject [{id}]")
    end
  end

  should "accept an address format with an ID marker" do
    FactCheckConfig.new("factcheck+{id}@example.com", "valid subject [{id}]")
  end

  should "fail on an address format with multiple ID markers" do
    assert_raises ArgumentError do
      FactCheckConfig.new("factcheck+{id}+{id}@example.com", "valid subject [{id}]")
    end
  end

  should "recognise a valid fact check address" do
    config = FactCheckConfig.new("factcheck+{id}@example.com", "valid subject [{id}]")
    assert config.valid_address?("factcheck+123456@example.com")
  end

  should "not recognise an invalid fact check address" do
    config = FactCheckConfig.new("factcheck+{id}@example.com", "valid subject [{id}]")
    assert_not config.valid_address?("not-factcheck@example.com")
  end

  should "not recognise a fact check address with an empty ID" do
    config = FactCheckConfig.new("factcheck+{id}@example.com", "valid subject [{id}]")
    assert_not config.valid_address?("factcheck+@example.com")
  end

  should "extract an item ID from a valid address" do
    config = FactCheckConfig.new("factcheck+{id}@example.com", "valid subject [{id}]")
    assert_equal "1234", config.item_id_from_address("factcheck+1234@example.com")
  end

  should "raise an exception trying to extract an ID from an invalid address" do
    config = FactCheckConfig.new("factcheck+{id}@example.com", "valid subject [{id}]")
    assert_raises ArgumentError do
      config.item_id_from_address("not-factcheck+1234@example.com")
    end
  end

  should "construct an address from an item ID" do
    config = FactCheckConfig.new("factcheck+{id}@example.com", "valid subject [{id}]")
    assert_equal "factcheck+1234@example.com", config.address("1234")
  end

  should "accept item IDs that aren't strings" do
    # For example, Mongo IDs, but let's not tie this test to Mongo
    config = FactCheckConfig.new("factcheck+{id}@example.com", "valid subject [{id}]")
    assert_equal "factcheck+1234@example.com", config.address(1234)
  end

  should "fail on a nil subject format" do
    assert_raises ArgumentError do
      FactCheckConfig.new("factcheck+{id}@example.com", nil)
    end
  end

  should "fail on an empty subject format" do
    assert_raises ArgumentError do
      FactCheckConfig.new("factcheck+{id}@example.com", "")
    end
  end

  should "fail on an subject format with no ID marker" do
    assert_raises ArgumentError do
      FactCheckConfig.new("factcheck+{id}@example.com", "Fact check subject")
    end
  end

  should "accept an subject format with an ID marker" do
    FactCheckConfig.new("factcheck+{id}@example.com", "Fact check subject [{id}]")
  end

  should "fail on an subject format with multiple ID markers" do
    assert_raises ArgumentError do
      FactCheckConfig.new("factcheck+{id}@example.com", "Fact check subject [{id}] [{id}]")
    end
  end

  should "recognise a valid fact check subject" do
    config = FactCheckConfig.new("factcheck+{id}@example.com", "Fact check subject [{id}]")
    assert config.valid_subject?("Fact check subject [1234]")
  end

  should "not recognise an invalid fact check subject" do
    config = FactCheckConfig.new("factcheck+{id}@example.com", "Fact check subject [{id}]")
    assert_not config.valid_subject?("Not a valid subject")
  end

  should "not recognise a fact check subject with an empty ID" do
    config = FactCheckConfig.new("factcheck+{id}@example.com", "Fact check subject [{id}]")
    assert_not config.valid_subject?("Not a valid subject []")
  end

  should "extract an item ID from a valid subject" do
    config = FactCheckConfig.new("factcheck+{id}@example.com", "Fact check subject [{id}]")
    assert_equal "1234", config.item_id_from_subject("Fact check subject [1234]")
  end

  should "raise an exception trying to extract an ID from an invalid subject" do
    config = FactCheckConfig.new("factcheck+{id}@example.com", "Fact check subject [{id}]")
    assert_raises ArgumentError do
      config.item_id_from_subject("Not a valid subject [1234]")
    end
  end

  should "construct an subject from an item ID" do
    config = FactCheckConfig.new("factcheck+{id}@example.com", "Fact check subject [{id}]")
    assert_equal "Fact check subject [1234]", config.subject("1234")
  end

  should "accept item IDs that aren't strings" do
    # For example, Mongo IDs, but let's not tie this test to Mongo
    config = FactCheckConfig.new("factcheck+{id}@example.com", "Fact check subject [{id}]")
    assert_equal "Fact check subject [1234]", config.subject(1234)
  end
end
