# encoding: utf-8
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
    fill_in "Description", :with => "Description of video"

    within :css, ".workflow_buttons" do
      click_on "Save"
    end

    assert page.has_content? @artefact.name

    video = VideoEdition.first
    assert_equal @artefact.id.to_s, video.panopticon_id

    assert_equal "Spinach and Agushi; Ghanaian street food", video.alternative_title
    assert_equal "http://www.youtube.com/watch?v=Wrcklaselbo", video.video_url
    assert_equal "A simple fried plantain recipe", video.video_summary
    assert_equal "Description of video", video.description
  end

  should "allow editing a VideoEdition" do
    video = FactoryGirl.create(:video_edition,
                                 :panopticon_id => @artefact.id,
                                 :title => "Foo bar",
                                 :video_url => "http://www.youtube.com/watch?v=qySFp3qnVmM",
                                 :video_summary => "Coke smoothie",
                                 :description => "Old description")

    visit "/admin/editions/#{video.to_param}"

    assert page.has_content? "Viewing “Foo bar” Edition 1"

    assert page.has_field?("Video URL", :with => "http://www.youtube.com/watch?v=qySFp3qnVmM")
    assert page.has_field?("Video Summary", :with => "Coke smoothie")
    assert page.has_field?("Description", :with => "Old description")

    fill_in "Video URL", :with => "http://www.youtube.com/watch?v=Wrcklaselbo"
    fill_in "Video Summary", :with => "A simple fried plantain recipe"
    fill_in "Description", :with => "Description of video"

    within ".workflow_buttons" do
      click_button "Save"
    end

    assert page.has_content? "Video edition was successfully updated."

    v = VideoEdition.find(video.id)
    assert_equal "http://www.youtube.com/watch?v=Wrcklaselbo", v.video_url
    assert_equal "A simple fried plantain recipe", v.video_summary
    assert_equal "Description of video", v.description
  end

  should "allow creating a new version of a VideoEdition" do
    video = FactoryGirl.create(:video_edition,
                                 :panopticon_id => @artefact.id,
                                 :state => 'published',
                                 :title => "Foo bar",
                                 :video_url => "http://www.youtube.com/watch?v=qySFp3qnVmM",
                                 :video_summary => "Coke smoothie",
                                 :description => "Description of video")

    visit "/admin/editions/#{video.to_param}"
    click_on "Create new edition"

    assert page.has_content? "Viewing “Foo bar” Edition 2"

    assert page.has_field?("Video URL", :with => "http://www.youtube.com/watch?v=qySFp3qnVmM")
    assert page.has_field?("Video Summary", :with => "Coke smoothie")
    assert page.has_field?("Description", :with => "Description of video")
  end
end
