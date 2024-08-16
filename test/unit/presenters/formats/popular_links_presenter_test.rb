require "test_helper"

class PopularLinksPresenterTest < ActiveSupport::TestCase
  def subject
    Formats::PopularLinksPresenter.new(FactoryBot.create(:popular_links))
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
      assert_equal ({ link_items: [{ url: "/url1", title: "title1" },
                                   { url: "/url2", title: "title2" },
                                   { url: "/url3", title: "title3" },
                                   { url: "/url4", title: "title4" },
                                   { url: "/url5", title: "title5" },
                                   { url: "/url6", title: "title6" }] }),
                   @result[:details]
    end

    should "have expected optional fields" do
      assert_not_empty @result[:access_limited]
      assert_not_empty @result[:public_updated_at]
    end
  end
end
