require "test_helper"

class PopularLinksEditionTest < ActiveSupport::TestCase
  should "save" do
    popular_links = FactoryBot.build(:popular_links)
    assert popular_links.save
  end

  should "validate 6 links are present" do
    link_items = [{ url: "url1", title: "title1" }]
    popular_links = FactoryBot.build(:popular_links, link_items:)

    assert_not popular_links.valid?
    assert_equal "6 links are required", popular_links.errors.messages[:link_items][0]
  end

  should "validate all links have url and title" do
    link_items = [{ url: "/url1", title: "" },
                  { title: "title2" },
                  { url: "/url3", title: "title3" },
                  { url: "/url4", title: "title4" },
                  { url: "/url5", title: "title5" },
                  { url: "/url6", title: "title6" }]
    popular_links = FactoryBot.build(:popular_links, link_items:)

    assert_not popular_links.valid?
    assert popular_links.errors.messages[:title1].include?("Title is required for Link 1")
    assert popular_links.errors.messages[:url2].include?("URL is required for Link 2")
  end

  should "validate all urls are valid" do
    link_items = [{ url: "", title: "" },
                  { url: "invalid", title: "title2" },
                  { url: "/abc", title: "title3" },
                  { url: "/cde", title: "title4" },
                  { url: "/efg", title: "title5" },
                  { url: "/hij", title: "title6" }]
    popular_links = FactoryBot.build(:popular_links, link_items:)

    assert_not popular_links.valid?
    assert popular_links.errors.messages[:url2].include?("URL is invalid for Link 2, all URLs should start with '/'")
    assert popular_links.errors.messages[:url1].include?("URL is required for Link 1")
  end

  should "create new record from last 'published' record with status as 'draft' and increased 'version_number'" do
    popular_links = FactoryBot.create(:popular_links, state: "published")

    assert_equal "published", PopularLinksEdition.last.state
    assert_equal 1, PopularLinksEdition.last.version_number

    popular_links.create_draft_popular_links_from_last_record

    assert_equal "draft", PopularLinksEdition.last.state
    assert_equal 2, PopularLinksEdition.last.version_number
  end
end
