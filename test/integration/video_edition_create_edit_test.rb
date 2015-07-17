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
    stub_collections
  end

  with_and_without_javascript do
    should "edit a new VideoEdition" do
      visit "/publications/#{@artefact.id}"

      assert page.has_content? @artefact.name

      fill_in "Video URL", :with => "http://www.youtube.com/watch?v=Wrcklaselbo"
      fill_in "Video Summary", :with => "A simple fried plantain recipe"
      fill_in "Body", :with => "Description of video"

      save_edition_and_assert_success

      assert page.has_content? @artefact.name

      video = VideoEdition.first
      assert_equal @artefact.id.to_s, video.panopticon_id

      assert_equal "http://www.youtube.com/watch?v=Wrcklaselbo", video.video_url
      assert_equal "A simple fried plantain recipe", video.video_summary
      assert_equal "Description of video", video.body
    end

    should "allow editing a VideoEdition" do
      video = FactoryGirl.create(:video_edition,
                                   :panopticon_id => @artefact.id,
                                   :title => "Foo bar",
                                   :video_url => "http://www.youtube.com/watch?v=qySFp3qnVmM",
                                   :video_summary => "Coke smoothie",
                                   :body => "Old description")

      visit "/editions/#{video.to_param}"

      assert page.has_content? 'Foo bar #1'
      assert page.has_field?("Video URL", :with => "http://www.youtube.com/watch?v=qySFp3qnVmM")
      assert page.has_field?("Video Summary", :with => "Coke smoothie")
      assert page.has_field?("Body", :with => "Old description")

      fill_in "Video URL", :with => "http://www.youtube.com/watch?v=Wrcklaselbo"
      fill_in "Video Summary", :with => "A simple fried plantain recipe"
      fill_in "Body", :with => "Description of video"

      save_edition_and_assert_success

      v = VideoEdition.find(video.id)
      assert_equal "http://www.youtube.com/watch?v=Wrcklaselbo", v.video_url
      assert_equal "A simple fried plantain recipe", v.video_summary
      assert_equal "Description of video", v.body
    end
  end

  should "allow creating a new version of a VideoEdition" do
    video = FactoryGirl.create(:video_edition,
                                 :panopticon_id => @artefact.id,
                                 :state => 'published',
                                 :title => "Foo bar",
                                 :video_url => "http://www.youtube.com/watch?v=qySFp3qnVmM",
                                 :video_summary => "Coke smoothie",
                                 :body => "Description of video")

    visit "/editions/#{video.to_param}"
    click_on "Create new edition"

    assert page.has_content? 'Foo bar #2'

    assert page.has_field?("Video URL", :with => "http://www.youtube.com/watch?v=qySFp3qnVmM")
    assert page.has_field?("Video Summary", :with => "Coke smoothie")
    assert page.has_field?("Body", :with => "Description of video")
  end

  should "manage caption files for a video edition" do
    edition = FactoryGirl.create(:video_edition, :state => 'draft')

    file_one = File.open(Rails.root.join("test","fixtures","uploads","captions.txt"))
    file_two = File.open(Rails.root.join("test","fixtures","uploads","captions_two.txt"))

    asset_one = OpenStruct.new(:id => 'http://asset-manager.dev.gov.uk/assets/an_image_id', :file_url => 'http://path/to/captions.txt')
    asset_two = OpenStruct.new(:id => 'http://asset-manager.dev.gov.uk/assets/another_image_id', :file_url => 'http://path/to/captions_two.txt')

    GdsApi::AssetManager.any_instance.stubs(:create_asset).returns(asset_one)
    GdsApi::AssetManager.any_instance.stubs(:asset).with("an_image_id").returns(asset_one)

    visit "/editions/#{edition.to_param}"

    assert page.has_field?("Upload a new caption file", :type => "file")
    attach_file("Upload a new caption file", file_one.path)
    save_edition_and_assert_success_slow

    within(:css, ".uploaded-caption-file") do
      assert_selector("a[href$='captions.txt']")
    end

    # ensure file is not removed on save
    save_edition_and_assert_success_slow

    within(:css, ".uploaded-caption-file") do
      assert_selector("a[href$='captions.txt']")
    end
  end

  should "disable fields for a published edition" do
    edition = FactoryGirl.create(:video_edition,
                                 :panopticon_id => @artefact.id,
                                 :state => 'published',
                                 :title => "Foo bar",
                                 :video_url => "http://www.youtube.com/watch?v=qySFp3qnVmM",
                                 :video_summary => "Coke smoothie",
                                 :body => "Description of video")

    visit "/editions/#{edition.to_param}"
    assert_all_edition_fields_disabled(page)
  end
end
