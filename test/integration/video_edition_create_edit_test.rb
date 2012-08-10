require "integration_test_helper"

class VideoEditionCreateEditTest < JavascriptIntegrationTest
  setup do
    @artefact = FactoryGirl.create(:artefact,
       slug: "ghanaian-curry",
       kind: "video",
       name: "Ghanaian curry",
       owning_app: "publisher")

    setup_users
  end

  should "edit a new VideoEdition" do
    visit "/admin/publications/#{@artefact.id}"

    assert page.has_content? @artefact.name

    fill_in "Alternative title", :with => "Spinach and Agushi; Ghanaian street food"
    fill_in "Video URL", :with => "http://www.youtube.com/watch?v=Wrcklaselbo"
    fill_in "Video Summary", :with => "A simple fried plantain recipe"

    within :css, ".workflow_buttons" do
      click_on "Save"
    end

    assert page.has_content? @artefact.name

    video = VideoEdition.first
    assert_equal @artefact.id.to_s, video.panopticon_id

    assert_equal "Spinach and Agushi; Ghanaian street food", video.alternative_title
    assert_equal "http://www.youtube.com/watch?v=Wrcklaselbo", video.video_url
    assert_equal "A simple fried plantain recipe", video.video_summary
  end
end
