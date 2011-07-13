require 'test_helper'

require 'guides_front_end'

class GuidesFrontEndTest < ActiveSupport::TestCase
  def setup
    @guides_front_end = GuidesFrontEnd::Preview.new
    @env = {'action_dispatch.request.path_parameters' => {:edition_id => 'the_edition'}}
  end

  test "the guides front end should be able to extract an edition ID in preview mode" do
    assert_equal 'the_edition', GuidesFrontEnd::Preview.preview_edition_id(@env)
  end
end