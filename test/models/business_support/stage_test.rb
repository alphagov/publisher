require 'test_helper'

class BusinessSupport::StageTest < ActiveSupport::TestCase
  setup do
    @stage = BusinessSupport::Stage.create(name: "Finance", slug: "finance")
  end

  test "should validates presence of name" do
    refute BusinessSupport::Stage.new(slug: "finance").valid?
  end

  test "should validate uniqueness of name" do
    another_scheme = BusinessSupport::Stage.new(name: "Finance", slug: "finance")
    refute another_scheme.valid?, "should validate uniqueness of name."
  end

  test "should validates presence of slug" do
    refute BusinessSupport::Stage.new(name: "Finance").valid?
  end

  test "should validate uniqueness of slug" do
    another_scheme = BusinessSupport::Stage.new(name: "Finance", slug: "finance")
    refute another_scheme.valid?, "should validate uniqueness of name."
  end
end
