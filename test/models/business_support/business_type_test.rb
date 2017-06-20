require 'test_helper'

class BusinessSupport::BusinessTypeTest < ActiveSupport::TestCase
  setup do
    @charity = BusinessSupport::BusinessType.create(name: "Charity", slug: "charity")
  end

  test "should validate presence of name" do
    refute BusinessSupport::BusinessType.new(slug: "charity").valid?
  end

  test "should validate uniqueness of name" do
    another_type = BusinessSupport::BusinessType.new(name: "Charity", slug: "charity")
    refute another_type.valid?, "should validate uniqueness of name."
  end

  test "should validate presence of slug" do
    refute BusinessSupport::BusinessType.new(name: "Charity").valid?
  end

  test "should validate uniqueness of slug" do
    another_type = BusinessSupport::BusinessType.new(name: "Charity", slug: "charity")
    refute another_type.valid?, "should validate uniqueness of slug."
  end
end
