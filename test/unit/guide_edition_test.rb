require 'test_helper'

class GuideTest < ActiveSupport::TestCase
  def template_guide
    g = Guide.new(:slug=>"childcare",:name=>"Something")
    edition = g.editions.first
    edition.title = 'One'
    g
  end
  
  test "order parts shouldn't fail if one part's order attribute is nil" do
    g = template_guide
    edition = g.editions.first
    edition.parts.build
    edition.parts.build(:order => 1)
    assert edition.order_parts
  end
end