require 'test_helper'

class VideoGenerationTest < ActiveSupport::TestCase
  setup do
    @video = FactoryGirl.create(:video_edition,
                                 :slug => 'test-slug',
                                 :title => 'Test Video',
                                 :alternative_title => 'This is an example video title',
                                 :video_url => "http://www.youtube.com/watch?v=qySFp3qnVmM",
                                 :video_summary => "Coke smoothie",
                                 :description => "Description of video")
  end

  def generated
    Api::Generator.edition_to_hash(@video)
  end

  should "return the standard data for a video" do
    result = generated
    assert_equal "Test Video", result['title']
    assert_equal "This is an example video title", result['alternative_title']
  end

  should "return the extra fields for a video" do
    result = generated
    assert_equal "video", result['type']
    assert_equal "Coke smoothie", result['video_summary']
    assert_equal "http://www.youtube.com/watch?v=qySFp3qnVmM", result['video_url']
    assert_equal "Description of video", result['description']
  end
end
