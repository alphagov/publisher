require 'test_helper'

class ProgrammeEditionTest < ActiveSupport::TestCase
  setup do
    stub_request(:get, /.*panopticon\.test\.gov\.uk\/artefacts\/.*\.js/).
      to_return(:status => 200, :body => "{}", :headers => {})
  end

  def template_programme
    p = ProgrammeEdition.new(:slug=>"childcare", :title=>"Children", :panopticon_id => FactoryGirl.create(:artefact).id)
    p.save
    p
  end

  test "order parts shouldn't fail if one part's order attribute is nil" do
    g = template_programme

    g.parts.build
    g.parts.build(:order => 1)
    assert g.order_parts
  end

  test "new programme has correct parts" do
    programme = template_programme
    assert_equal 5, programme.parts.length
    ProgrammeEdition::DEFAULT_PARTS.each_with_index { |part, index|
      assert_equal part[:title], programme.parts[index].title
    }
  end

end
