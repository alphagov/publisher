require 'test_helper'

require 'guides_front_end'

class GuidesFrontEndTest < ActiveSupport::TestCase
  def setup
    @guides_front_end = GuidesFrontEnd.new
    @env = {'action_dispatch.request.path_parameters' => {:edition_id => 'the_edition'}}
  end

  test "the guides front end should be able to recognise that it's mounted in the rails app (and therefore in preview mode)" do
    assert GuidesFrontEnd.preview_mode?(@env)
  end
  test "the guides front end should be able to extract an edition ID in preview mode" do
    assert_equal 'the_edition', GuidesFrontEnd.preview_edition_id(@env)
  end
end