require "test_helper"

class SitemapControllerTest < ActionController::TestCase
  context "with no editions" do
    should "return an empty XML file" do
      get :index

      assert_response :success

      assert_select "url > loc", false
    end
  end

  context "with an edition" do
    setup do
      FactoryBot.create(:guide_edition, :published, slug: "test-path")
    end

    should "return an XML file containing the URL" do
      get :index

      assert_response :success

      assert_select "url > loc", { text: "http://www.dev.gov.uk/test-path", count: 1 }
    end
  end

  context "with an edition and a part" do
    setup do
      edition = FactoryBot.create(:guide_edition, :published, slug: "test-path")
      edition.parts.create!(title: "Test title", body: "Test body", slug: "test-part")
    end

    should "return an XML file containing the URLs" do
      get :index

      assert_response :success

      urls = []
      assert_select "url > loc", count: 2 do |elements|
        urls = elements.map { |e| e.children.first.content }
      end

      assert_same_elements urls, %w[http://www.dev.gov.uk/test-path http://www.dev.gov.uk/test-path/test-part]
    end
  end
end
