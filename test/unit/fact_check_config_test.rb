require "test_helper"
require "fact_check_config"

class FactCheckConfigTest < ActiveSupport::TestCase
  valid_address = "factcheck+1234@example.com"
  valid_address_pattern = "factcheck+{id}@example.com"
  reply_to_address = valid_address
  valid_subjects = ["‘[Some title]’ GOV.UK preview of new edition [5e6bb57b40f0b62656e3e184]",
                    "‘[Some title]’ GOV.UK preview of new edition [5e6bb57b40f0b62656e3e184] - ticket #5678",
                    "‘[123456]’ GOV.UK preview of new edition [5e6bb57b40f0b62656e3e184]",
                    "‘[123456]’ GOV.UK preview of new edition [5e6bb57b40f0b62656e3e184] - ticket #5678",
                    "I've edited the subject but left the ID at the end [5e6bb57b40f0b62656e3e184]",
                    "I've edited the subject and appended something [5e6bb57b40f0b62656e3e184] - ticket #2468"]
  valid_prefixed_subjects = valid_subjects.map { |subject| subject.gsub(/\[5e6bb57b40f0b62656e3e184\]/, "[test-5e6bb57b40f0b62656e3e184]") }

  should "fail on a nil address format" do
    assert_raises ArgumentError do
      FactCheckConfig.new(nil, reply_to_address)
    end
  end

  should "fail on a nil reply-to address" do
    assert_raises ArgumentError do
      FactCheckConfig.new(valid_address_pattern, nil)
    end
  end

  should "fail on an empty address format" do
    assert_raises ArgumentError do
      FactCheckConfig.new("", reply_to_address)
    end
  end

  should "fail on an empty reply-to address" do
    assert_raises ArgumentError do
      FactCheckConfig.new(valid_address_pattern, "")
    end
  end

  should "fail on an address format with no ID marker" do
    assert_raises ArgumentError do
      FactCheckConfig.new("factcheck@example.com", reply_to_address)
    end
  end

  should "accept an address format with an ID marker" do
    FactCheckConfig.new(valid_address_pattern, reply_to_address)
  end

  should "fail on an address format with multiple ID markers" do
    assert_raises ArgumentError do
      FactCheckConfig.new("factcheck+{id}+{id}@example.com", reply_to_address)
    end
  end

  should "recognise a valid fact check address" do
    config = FactCheckConfig.new(valid_address_pattern, reply_to_address)
    assert config.valid_address?(valid_address)
  end

  should "not recognise an invalid fact check address" do
    config = FactCheckConfig.new(valid_address_pattern, reply_to_address)
    assert_not config.valid_address?("not-factcheck@example.com")
  end

  should "not recognise a fact check address with an empty ID" do
    config = FactCheckConfig.new(valid_address_pattern, reply_to_address)
    assert_not config.valid_address?("factcheck+@example.com")
  end

  should "extract an item ID from a valid address" do
    config = FactCheckConfig.new(valid_address_pattern, reply_to_address)
    assert_equal "1234", config.item_id_from_address(valid_address)
  end

  should "raise an exception trying to extract an ID from an invalid address" do
    config = FactCheckConfig.new(valid_address_pattern, reply_to_address)
    assert_raises ArgumentError do
      config.item_id_from_address("not-factcheck+1234@example.com")
    end
  end

  should "return a static reply-to address regardless of id" do
    config = FactCheckConfig.new(valid_address_pattern, reply_to_address)
    assert_equal reply_to_address, config.address
  end

  should "recognise a valid fact check subject" do
    config = FactCheckConfig.new(valid_address_pattern, reply_to_address)
    valid_subjects.each do |valid_subject|
      assert config.valid_subject?(valid_subject)
    end
  end

  should "recognise a valid fact check subject with a prefix" do
    config = FactCheckConfig.new(valid_address_pattern, reply_to_address, "test")
    valid_prefixed_subjects.each do |valid_prefixed_subject|
      assert config.valid_subject?(valid_prefixed_subject)
    end
    valid_subjects.each do |valid_subject|
      assert_not config.valid_subject?(valid_subject)
    end
  end

  should "not recognise an invalid fact check subject" do
    config = FactCheckConfig.new(valid_address_pattern, reply_to_address)
    assert_not config.valid_subject?("Not a valid subject")
  end

  should "treat a subject prefixed with Re: as valid" do
    config = FactCheckConfig.new(valid_address_pattern, reply_to_address)
    valid_subjects.each do |valid_subject|
      assert config.valid_subject?("Re: " + valid_subject)
    end
  end

  should "not recognise a fact check subject with an empty ID" do
    config = FactCheckConfig.new(valid_address_pattern, reply_to_address)
    assert_not config.valid_subject?("Not a valid subject []")
  end

  should "extract an item ID from a valid subject" do
    config = FactCheckConfig.new(valid_address_pattern, reply_to_address)
    valid_subjects.each do |valid_subject|
      assert_equal "5e6bb57b40f0b62656e3e184", config.item_id_from_subject(valid_subject)
    end
  end

  should "raise an exception trying to extract an ID from an invalid subject" do
    config = FactCheckConfig.new(valid_address_pattern, reply_to_address)
    assert_raises ArgumentError do
      config.item_id_from_subject("Not a valid subject (1234)")
    end

    assert_raises ArgumentError do
      config.item_id_from_subject("Not a valid subject [notHexadecimal]")
    end
  end

  should "raise an exception if there are multiple matches" do
    config = FactCheckConfig.new(valid_address_pattern, reply_to_address)
    valid_subjects.each do |valid_subject|
      assert_equal false, config.valid_subject?(valid_subject + " [d682605bec3cf9b8906cf2bc]")

      assert_raises ArgumentError do
        config.item_id_from_subject(valid_subject + " [d682605bec3cf9b8906cf2bc]")
      end
    end
  end
end
