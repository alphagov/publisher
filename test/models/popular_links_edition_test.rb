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
    assert popular_links.errors[:link_items].any?
  end

  should "validate all links have url" do
    link_items = [{ title: "title1" },
                  { url: "url2", title: "title2" },
                  { url: "url3", title: "title3" },
                  { url: "url4", title: "title4" },
                  { url: "url5", title: "title5" },
                  { url: "url6", title: "title6" }]
    popular_links = FactoryBot.build(:popular_links, link_items:)

    assert_not popular_links.valid?
    assert_equal popular_links.errors[:item][0], "A URL is required for Link 1"
  end

  should "validate all links have title" do
    link_items = [{ url: "url1" },
                  { url: "url2", title: "title2" },
                  { url: "url3", title: "title3" },
                  { url: "url4", title: "title4" },
                  { url: "url5", title: "title5" },
                  { url: "url6", title: "title6" }]
    popular_links = FactoryBot.build(:popular_links, link_items:)

    assert_not popular_links.valid?
    assert_equal popular_links.errors[:item][0], "A Title is required for Link 1"
  end
end
