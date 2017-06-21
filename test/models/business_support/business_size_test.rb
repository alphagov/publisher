require 'test_helper'

class BusinessSupport::BusinessSizeTest < ActiveSupport::TestCase
  setup do
    @charity = BusinessSupport::BusinessSize.create(name: "Under 10", slug: "under-10")
  end

  test "should validate presence of name" do
    refute BusinessSupport::BusinessSize.new(slug: "under-10").valid?
  end

  test "should validate uniqueness of name" do
    another_type = BusinessSupport::BusinessSize.new(name: "Under 10", slug: "under-10")
    refute another_type.valid?, "should validate uniqueness of name."
  end

  test "should validate presence of slug" do
    refute BusinessSupport::BusinessSize.new(name: "Under 10").valid?
  end

  test "should validate uniqueness of slug" do
    another_type = BusinessSupport::BusinessSize.new(name: "Under 10", slug: "under-10")
    refute another_type.valid?, "should validate uniqueness of slug."
  end
end
