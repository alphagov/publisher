require "test_helper"

class HomepageControllerTest < ActionController::TestCase
  setup do
    login_as_homepage_editor
  end

  context "#show" do
    setup do
      @popular_links = FactoryBot.create(:popular_links)
    end

    should "render show template" do
      get :show

      assert_response :ok
      assert_template "homepage/popular_links/show"
    end
  end

  context "#create" do
    setup do
      @popular_links = FactoryBot.create(:popular_links, state: "published")
    end

    should "render show template" do
      post :create, params: { id: @popular_links.id }

      assert_response :ok
      assert_template "homepage/popular_links/show"
    end

    should "create a new draft popular links" do
      assert_equal 1, PopularLinksEdition.count
      assert_equal "published", PopularLinksEdition.last.state

      post :create, params: { id: @popular_links.id }

      assert_equal 2, PopularLinksEdition.count
      assert_equal "draft", PopularLinksEdition.last.state
    end
  end

  context "#edit" do
    should "render edit template" do
      popular_links = FactoryBot.create(:popular_links, state: "published")

      post :edit, params: { id: popular_links.id }

      assert_response :ok
      assert_template "homepage/popular_links/edit"
    end
  end

  context "#update" do
    setup do
      @popular_links = FactoryBot.create(:popular_links, state: "draft")
    end

    should "update latest PopularLinksEdition with changed title and url" do
      assert_equal "title1", @popular_links.link_items[0][:title]
      assert_equal "https://www.url1.com", @popular_links.link_items[0][:url]

      new_title = "title has changed"
      new_url = "https://www.changedurl.com"
      patch :update, params: { id: @popular_links.id,
                               "popular_links" =>
                                 { "1" => { "title" => new_title, "url" => new_url },
                                   "2" => { "title" => "title2", "url" => "https://www.url2.com" },
                                   "3" => { "title" => "title3", "url" => "https://www.url3.com" },
                                   "4" => { "title" => "title4", "url" => "https://www.url4.com" },
                                   "5" => { "title" => "title5", "url" => "https://www.url5.com" },
                                   "6" => { "title" => "title6", "url" => "https://www.url6.com" } } }

      assert_equal new_title, PopularLinksEdition.last.link_items[0][:title]
      assert_equal new_url, PopularLinksEdition.last.link_items[0][:url]
    end

    should "update publishing API" do
      Services.publishing_api.expects(:put_content).with(@popular_links.content_id, has_entry(:title, "Homepage Popular Links"))

      patch :update, params: { id: @popular_links.id,
                               "popular_links" =>
                                 { "1" => { "title" => "title", "url" => "url.com" },
                                   "2" => { "title" => "title2", "url" => "https://www.url2.com" },
                                   "3" => { "title" => "title3", "url" => "https://www.url3.com" },
                                   "4" => { "title" => "title4", "url" => "https://www.url4.com" },
                                   "5" => { "title" => "title5", "url" => "https://www.url5.com" },
                                   "6" => { "title" => "title6", "url" => "https://www.url6.com" } } }
    end

    should "redirect to show path on success" do
      new_title = "title has changed"

      patch :update, params: { id: @popular_links.id,
                               "popular_links" =>
                                 { "1" => { "title" => new_title, "url" => "https://www.url1.com" },
                                   "2" => { "title" => "title2", "url" => "https://www.url2.com" },
                                   "3" => { "title" => "title3", "url" => "https://www.url3.com" },
                                   "4" => { "title" => "title4", "url" => "https://www.url4.com" },
                                   "5" => { "title" => "title5", "url" => "https://www.url5.com" },
                                   "6" => { "title" => "title6", "url" => "https://www.url6.com" } } }

      assert_redirected_to show_popular_links_path
    end

    should "render edit template on errors" do
      patch :update, params: { id: @popular_links.id,
                               "popular_links" =>
                                 { "1" => { "title" => "title has changed", "url" => "https://www.url1.com" } } }

      assert_template "homepage/popular_links/edit"
    end
  end

  context "#publish" do
    setup do
      @popular_links = FactoryBot.create(:popular_links, state: "draft")
    end

    should "publish latest draft popular links and render show template" do
      assert_equal "draft", PopularLinksEdition.last.state

      post :publish, params: { id: @popular_links.id }

      assert_response :ok
      assert_template "homepage/popular_links/show"
      assert_equal "published", PopularLinksEdition.last.state
    end

    should "publish to publishing API" do
      Services.publishing_api.expects(:publish).with(@popular_links.content_id, "major", locale: "en")

      post :publish, params: { id: @popular_links.id }
    end
  end
end
