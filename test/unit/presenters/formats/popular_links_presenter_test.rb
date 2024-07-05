require "test_helper"

class PopularLinksPresenterTest < ActiveSupport::TestCase
  def subject
    updated_at_time = Time.parse("Thu, 11 Jul 2024 10:47:27.397934771 UTC")
    Formats::PopularLinksPresenter.new(FactoryBot.create(:popular_links, updated_at: updated_at_time))
  end

  context "#render_for_publishing_api" do
    setup do
      @result = subject.render_for_publishing_api
    end

    should "be valid against schema" do
      assert_valid_against_publisher_schema(@result, "link_collection")
    end

    should "have expected required fields" do
      assert_equal "Homepage Popular Links", @result[:title]
      assert_equal "link_collection", @result[:schema_name]
      assert_equal "link_collection", @result[:document_type]
      assert_equal "publisher", @result[:publishing_app]
      assert_equal "frontend", @result[:rendering_app]
      assert_equal ({ link_items: [{ url: "https://www.url1.com", title: "title1" },
                                   { url: "https://www.url2.com", title: "title2" },
                                   { url: "https://www.url3.com", title: "title3" },
                                   { url: "https://www.url4.com", title: "title4" },
                                   { url: "https://www.url5.com", title: "title5" },
                                   { url: "https://www.url6.com", title: "title6" }] }),
                   @result[:details]
    end

    should "have expected optional fields" do
      assert_not_empty @result[:access_limited]
      assert_not_empty @result[:public_updated_at]
    end
  end
end
