require 'test_helper'

class BusinessSupport::SupportTypeTest < ActiveSupport::TestCase
  setup do
    @type = BusinessSupport::SupportType.create(name: "Loan", slug: "loan")
  end

  test "should validates presence of name" do
    refute BusinessSupport::SupportType.new(slug: "short-term-loan").valid?
  end

  test "should validate uniqueness of name" do
    another_scheme = BusinessSupport::SupportType.new(name: "Loan", slug: "short-term-loan")
    refute another_scheme.valid?, "should validate uniqueness of name."
  end

  test "should validates presence of slug" do
    refute BusinessSupport::SupportType.new(name: "Loan").valid?
  end

  test "should validate uniqueness of slug" do
    another_scheme = BusinessSupport::SupportType.new(name: "Loan", slug: "loan")
    refute another_scheme.valid?, "should validate uniqueness of name."
  end
end
