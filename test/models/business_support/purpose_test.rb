require 'test_helper'

class BusinessSupport::PurposeTest < ActiveSupport::TestCase
  setup do
    @purpose = BusinessSupport::Purpose.create(name: "Setting up your business",
                                               slug: "setting-up-your-business")
  end

  test "should validates presence of name" do
    refute BusinessSupport::Purpose.new(slug: "setting-up-your-business").valid?
  end

  test "should validate uniqueness of name" do
    another_purpose = BusinessSupport::Purpose.new(name: "Setting up your business",
                                                  slug: "setting-up-your-business")
    refute another_purpose.valid?, "should validate uniqueness of name."
  end

  test "should validates presence of slug" do
    refute BusinessSupport::Purpose.new(name: "Setting up your business").valid?
  end

  test "should validate uniqueness of slug" do
    another_scheme = BusinessSupport::Purpose.new(name: "Setting up your business",
                                                 slug: "setting-up-your-business")
    refute another_scheme.valid?, "should validate uniqueness of name."
  end
end
