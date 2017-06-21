require 'test_helper'

class BusinessSupport::LocationTest < ActiveSupport::TestCase
  setup do
    @region = BusinessSupport::Location.create(name: "Ecclefechan", slug: "ecclefechan")
  end

  test "should validates presence of name" do
    refute BusinessSupport::Location.new(slug: "ecclefechan").valid?
  end

  test "should validate uniqueness of name" do
    another_scheme = BusinessSupport::Location.new(name: "Ecclefechan", slug: "ecclefechan")
    refute another_scheme.valid?, "should validate uniqueness of name."
  end

  test "should validate presence of slug" do
    refute BusinessSupport::Location.new(name: "Ecclefechan").valid?
  end

  test "should validate uniqueness of slug" do
    another_scheme = BusinessSupport::Location.new(name: "Ecclefechan", slug: "ecclefechan")
    refute another_scheme.valid?, "should validate uniqueness of slug"
  end
end
