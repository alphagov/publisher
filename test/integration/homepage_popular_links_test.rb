require "integration_test_helper"

class HomepagePopularLinksTest < JavascriptIntegrationTest
  setup do
    setup_users
    @popular_links = FactoryBot.create(:popular_links, state: "published")
    visit_popular_links
  end

  context "#show" do
    should "render page title" do
      assert_title "Popular on GOV.UK"
    end

    should "render 'Homepage' as a page title context" do
      assert page.has_content?("Homepage")
    end

    should "have 6 links with title and url" do
      assert page.has_css?(".govuk-summary-card__title", count: 6)
      assert page.has_text?("Title", count: 6)
      assert page.has_text?("URL", count: 6)
    end

    should "have popular links version and status" do
      assert page.has_text?("Edition")
      assert page.has_text?(@popular_links.version_number)
      assert page.has_text?("Status")
      assert page.has_text?("Published")
      assert page.has_css?(".govuk-tag--green")
    end

    should "have link to view 'GOV.UK'" do
      assert page.has_link?("View on GOV.UK (opens in new tab)", href: Plek.website_root)
    end

    should "have 'Create new edition' button" do
      assert page.has_text?("Create new edition")
    end

    should "navigate to create path on click of 'Create new edition'" do
      click_button("Create new edition")
      assert_current_path create_popular_links_path
    end

    should "render new draft popular links with edit option when 'Create new edition' button is clicked" do
      click_button("Create new edition")
      within(:css, ".govuk-tag--yellow") do
        assert page.has_content?("Draft")
      end
    end
  end

  context "#create" do
    should "create and show new edition with draft status and with an option to edit popular links" do
      click_button("Create new edition")

      assert page.has_text?("Edition")
      assert page.has_text?(@popular_links.version_number)
      assert page.has_text?("Status")
      assert page.has_text?("Draft")
      assert page.has_css?(".govuk-tag--yellow")
      assert page.has_text?("Edit popular links")
    end

    should "have link to preview on draft-origin" do
      click_button("Create new edition")

      assert page.has_link?("Preview (opens in new tab)", href: /#{Plek.external_url_for('draft-origin')}/)
    end

    should "have 'delete draft' link navigating to 'confirm destroy' page" do
      click_button("Create new edition")

      assert page.has_link?("Delete draft", href: /confirm-destroy/)
    end

    should "create a new record with next version and 'draft' status" do
      row = find_all(".govuk-summary-list__row")
      assert row[0].has_text?("Edition")
      assert row[0].has_text?("1")
      assert row[1].has_text?("Status")
      assert row[1].has_text?("Published")

      click_button("Create new edition")

      row = find_all(".govuk-summary-list__row")
      assert row[0].has_text?("Edition")
      assert row[0].has_text?("2")
      assert row[1].has_text?("Status")
      assert row[1].has_text?("Draft")
    end
  end

  context "#edit" do
    setup do
      click_button("Create new edition")
      click_link("Edit popular links")
    end

    should "render page title" do
      assert_title "Edit popular links"
    end

    should "render 'Popular on GOV.UK' as a page title context" do
      assert page.has_content?("Popular on GOV.UK")
    end

    should "have 6 links with title and url" do
      assert page.has_css?(".govuk-input", count: 12)
      assert page.has_text?("Title", count: 6)
      assert page.has_text?("URL", count: 6)
    end

    should "update record when 'Save' is clicked" do
      fill_in "popular_links[1][title]", with: "new title 1"
      click_button("Save")

      assert page.has_text?("Popular links draft saved.")
      assert page.has_text?("new title 1")
    end

    should "show validation errors for missing link and url" do
      fill_in "popular_links[1][title]", with: ""
      fill_in "popular_links[1][url]", with: ""
      click_button("Save")

      assert page.has_text?("Title is required for Link 1")
      assert page.has_text?("URL is required for Link 1")
    end

    should "trim spaces from start and end of urls" do
      fill_in "popular_links[1][url]", with: " /abc "
      click_button("Save")

      assert page.has_text?("/abc")
      assert_not page.has_text?(" /abc ")
    end

    should "render create page when 'Cancel' is clicked" do
      click_link("Cancel")

      assert_current_path show_popular_links_path
    end

    should "not save any changes when 'Cancel' is clicked" do
      fill_in "popular_links[1][url]", with: "/abc"
      click_link("Cancel")

      assert_not page.has_text?("/abc")
    end
  end

  context "#publish" do
    setup do
      click_button("Create new edition")
    end

    should "publish latest edition when 'Publish' is clicked" do
      click_button("Publish")

      assert page.has_text?("Published")
      assert page.has_text?("Popular links successfully published.")
    end
  end

  context "#confirm_destroy" do
    setup do
      click_button("Create new edition")
    end

    should "show the 'Delete draft' confirmation page" do
      click_link("Delete draft")

      assert page.has_text?("Delete draft")
      assert page.has_text?("Are you sure you want to delete this draft?")
    end

    should "navigate to show page when 'Cancel' button is clicked" do
      click_link("Delete draft")
      click_link("Cancel")

      assert_title "Popular on GOV.UK"
    end
  end

  context "#destroy" do
    setup do
      click_button("Create new edition")
    end

    should "show the previously published edition when a draft is deleted" do
      row = find_all(".govuk-summary-list__row")
      assert row[0].has_text?("Edition")
      assert row[0].has_text?("2")
      assert row[1].has_text?("Draft")

      click_link("Delete draft")
      click_button("Delete")

      row = find_all(".govuk-summary-list__row")
      assert row[0].has_text?("Edition")
      assert row[0].has_text?("1")
      assert row[1].has_text?("Published")
    end
  end

  def visit_popular_links
    visit "/homepage/popular-links"
  end
end
