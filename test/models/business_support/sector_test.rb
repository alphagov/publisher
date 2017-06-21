require 'test_helper'

class BusinessSupport::SectorTest < ActiveSupport::TestCase
  setup do
    @sector = BusinessSupport::Sector.create(name: "Manufacturing", slug: "manufacturing")
  end

  test "should validates presence of name" do
    refute BusinessSupport::Sector.new(slug: "manufacturing").valid?
  end

  test "should validate uniqueness of name" do
    another_scheme = BusinessSupport::Sector.new(name: "Manufacturing", slug: "manufacturing")
    refute another_scheme.valid?, "should validate uniqueness of name."
  end

  test "should validates presence of slug" do
    refute BusinessSupport::Sector.new(name: "Manufacturing").valid?
  end

  test "should validate uniqueness of slug" do
    another_scheme = BusinessSupport::Sector.new(name: "Manufacturing", slug: "manufacturing")
    refute another_scheme.valid?, "should validate uniqueness of name."
  end
end
