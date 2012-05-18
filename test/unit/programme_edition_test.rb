require 'test_helper'

class ProgrammeEditionTest < ActiveSupport::TestCase
  setup do
    stub_request(:get, /.*panopticon\.test\.gov\.uk\/artefacts\/.*\.js/).
      to_return(:status => 200, :body => "{}", :headers => {})
  end

  def template_programme
    p = ProgrammeEdition.new(:slug=>"childcare", :title=>"Children", :panopticon_id => 987353)
    p.start_work
    p.save
    p
  end

  test "order parts shouldn't fail if one part's order attribute is nil" do
    g = template_programme

    g.parts.build
    g.parts.build(:order => 1)
    assert g.order_parts
  end

  test 'a programme correctly formats the additional links' do
    programme = template_programme
    programme.update_attribute(:state,'published')
    programme.save

    out = programme.search_index
    assert_equal 5, out['additional_links'].count
    assert_equal '/childcare#overview', out['additional_links'].first['link']
    assert_equal '/childcare/further-information', out['additional_links'].last['link']
  end

  test "new programme has correct parts" do
    programme = template_programme
    assert_equal 5, programme.parts.length
    ProgrammeEdition::DEFAULT_PARTS.each_with_index { |part, index|
      assert_equal part[:title], programme.parts[index].title
    }
  end

end
