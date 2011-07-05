require 'test_helper'


class GuideTest < ActiveSupport::TestCase

  def template_guide
    g = Guide.new(:slug=>"childcare")
    edition = g.editions.first
    edition.title = 'One'
    g.editions.build(:title => 'Two')
    g
  end
  
  test 'guides assume the title of their latest edition' do
    assert_equal template_guide.title, 'Two'
  end
end