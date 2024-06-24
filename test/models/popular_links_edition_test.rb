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
    link_items = [{ url: "https://www.url1.com", title: "" },
                  { title: "title2" },
                  { url: "https://www.url3.com", title: "title3" },
                  { url: "https://www.url4.com", title: "title4" },
                  { url: "https://www.url5.com", title: "title5" },
                  { url: "https://www.url6.com", title: "title6" }]
    popular_links = FactoryBot.build(:popular_links, link_items:)

    assert_not popular_links.valid?
    assert popular_links.errors.full_messages.include?("Title is required for Link 1")
    assert popular_links.errors.full_messages.include?("URL is required for Link 2")
  end

  should "validate all urls are valid" do
    link_items = [{ url: "", title: "" },
                  { url: "invalid", title: "title2" },
                  { url: "www.abc.co.uk", title: "title3" },
                  { url: "www.cde.co.uk", title: "title4" },
                  { url: "www.efg.co.uk", title: "title5" },
                  { url: "www.ijk.com", title: "title6" }]
    popular_links = FactoryBot.build(:popular_links, link_items:)
    assert_not popular_links.valid?
    assert popular_links.errors.full_messages.include?("URL is invalid for Link 2")
    assert popular_links.errors.full_messages.include?("URL is required for Link 1")
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
