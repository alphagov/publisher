require 'test_helper'

class GuideEditionTest < ActiveSupport::TestCase
  def template_guide
    FactoryGirl.create(:guide_edition, title: 'One')
  end

  test "order parts shouldn't fail if one part's order attribute is nil" do
    edition = template_guide
    edition.parts.build
    edition.parts.build(:order => 1)
    assert edition.order_parts
  end
end