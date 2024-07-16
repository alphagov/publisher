require "test_helper"

class HomepageControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
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

    should "render edit template on validation error" do
      links_with_missing_items = { "1" => { "title" => "title has changed", "url" => "https://www.url1.com" } }

      patch :update, params: { id: @popular_links.id,
                               "popular_links" => links_with_missing_items }

      assert_template "homepage/popular_links/edit"
    end

    context "database errors" do
      setup do
        PopularLinksEdition.any_instance.stubs(:save).raises(Mongoid::Errors::MongoidError.new)
      end

      should "alert 'application error'" do
        new_title = "title has changed"

        patch :update, params: { id: @popular_links.id,
                                 "popular_links" =>
                                   { "1" => { "title" => new_title, "url" => "https://www.url1.com" },
                                     "2" => { "title" => "title2", "url" => "https://www.url2.com" },
                                     "3" => { "title" => "title3", "url" => "https://www.url3.com" },
                                     "4" => { "title" => "title4", "url" => "https://www.url4.com" },
                                     "5" => { "title" => "title5", "url" => "https://www.url5.com" },
                                     "6" => { "title" => "title6", "url" => "https://www.url6.com" } } }

        assert_equal "Due to an application error, the edition couldn't be saved.", flash[:danger]
      end

      should "render edit template" do
        new_title = "title has changed"

        patch :update, params: { id: @popular_links.id,
                                 "popular_links" =>
                                   { "1" => { "title" => new_title, "url" => "https://www.url1.com" },
                                     "2" => { "title" => "title2", "url" => "https://www.url2.com" },
                                     "3" => { "title" => "title3", "url" => "https://www.url3.com" },
                                     "4" => { "title" => "title4", "url" => "https://www.url4.com" },
                                     "5" => { "title" => "title5", "url" => "https://www.url5.com" },
                                     "6" => { "title" => "title6", "url" => "https://www.url6.com" } } }

        assert_template "homepage/popular_links/edit"
      end
    end

    context "publishing api errors" do
      setup do
        stub_publishing_api_put_content_error
      end

      should "render edit template on publishing api error" do
        new_title = "title has changed"

        patch :update, params: { id: @popular_links.id,
                                 "popular_links" =>
                                   { "1" => { "title" => new_title, "url" => "https://www.url1.com" },
                                     "2" => { "title" => "title2", "url" => "https://www.url2.com" },
                                     "3" => { "title" => "title3", "url" => "https://www.url3.com" },
                                     "4" => { "title" => "title4", "url" => "https://www.url4.com" },
                                     "5" => { "title" => "title5", "url" => "https://www.url5.com" },
                                     "6" => { "title" => "title6", "url" => "https://www.url6.com" } } }

        assert_template "homepage/popular_links/edit"
      end

      should "alert 'save was unsuccessful due to a service problem'" do
        new_title = "title has changed"

        patch :update, params: { id: @popular_links.id,
                                 "popular_links" =>
                                   { "1" => { "title" => new_title, "url" => "https://www.url1.com" },
                                     "2" => { "title" => "title2", "url" => "https://www.url2.com" },
                                     "3" => { "title" => "title3", "url" => "https://www.url3.com" },
                                     "4" => { "title" => "title4", "url" => "https://www.url4.com" },
                                     "5" => { "title" => "title5", "url" => "https://www.url5.com" },
                                     "6" => { "title" => "title6", "url" => "https://www.url6.com" } } }

        assert_equal "Popular links save was unsuccessful due to a service problem. Please wait for a few minutes and try again.", flash[:danger]
      end
    end
  end

  context "#publish" do
    setup do
      @popular_links = FactoryBot.create(:popular_links, state: "draft")
    end

    should "publish latest draft popular links and render show template" do
      assert_equal "draft", PopularLinksEdition.last.state

      post :publish, params: { id: @popular_links.id }

      assert_redirected_to show_popular_links_path
      assert_equal "published", PopularLinksEdition.last.state
    end

    context "database errors" do
      setup do
        PopularLinksEdition.any_instance.stubs(:publish_popular_links).raises(Mongoid::Errors::MongoidError.new)
      end

      should "redirect to show path" do
        post :publish, params: { id: @popular_links.id }

        assert_redirected_to show_popular_links_path
      end

      should "alert 'application error'" do
        post :publish, params: { id: @popular_links.id }

        assert_equal "Due to an application error, the edition couldn't be published.", flash[:danger]
      end
    end

    context "publishing api errors" do
      should "redirect to show path" do
        stub_publishing_api_publish_already_published_error

        post :publish, params: { id: @popular_links.id }

        assert_redirected_to show_popular_links_path
      end

      should "alert 'cannot publish an already published content' when already published content error" do
        stub_publishing_api_publish_already_published_error

        post :publish, params: { id: @popular_links.id }

        assert_equal "Popular links publish was unsuccessful, cannot publish an already published content item.", flash[:danger]
      end

      should "alert 'unsuccessful due to a service problem'" do
        stub_publishing_api_publish_downstream_error

        post :publish, params: { id: @popular_links.id }

        assert_equal "Popular links publish was unsuccessful due to a service problem. Please wait for a few minutes and try again.", flash[:danger]
      end
    end
  end

private

  def stub_publishing_api_publish_already_published_error
    stub_request(
      :post,
      "#{Plek.find('publishing-api')}/v2/content/#{@popular_links.content_id}/publish",
    ).to_return(
      status: 409,
      body: {
        "error" => {
          "code" => 409, "message" => "Cannot publish an already published content item"
        },
      }.to_json,
    )
  end

  def stub_publishing_api_publish_downstream_error
    stub_request(
      :post,
      "#{Plek.find('publishing-api')}/v2/content/#{@popular_links.content_id}/publish",
    ).to_return(
      status: 500,
      body: {
        "error" => {
          "code" => 500, "message" => "downstream error"
        },
      }.to_json,
    )
  end

  def stub_publishing_api_put_content_error
    stub_request(
      :put,
      "#{Plek.find('publishing-api')}/v2/content/#{@popular_links.content_id}",
    ).to_return(
      status: 409,
    )
  end
end
