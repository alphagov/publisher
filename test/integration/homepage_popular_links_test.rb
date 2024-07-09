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
      assert page.has_text?("PUBLISHED")
      assert page.has_css?(".govuk-tag--green")
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
        assert page.has_content?("DRAFT")
      end
    end
  end

  context "#create" do
    should "create and show new edition with draft status and with an option to edit popular links" do
      click_button("Create new edition")

      assert page.has_text?("Edition")
      assert page.has_text?(@popular_links.version_number)
      assert page.has_text?("Status")
      assert page.has_text?("DRAFT")
      assert page.has_css?(".govuk-tag--yellow")
      assert page.has_text?("Edit popular links")
    end

    should "create a new record with next version and 'draft' status" do
      row = find_all(".govuk-summary-list__row")
      assert row[0].has_text?("Edition")
      assert row[0].has_text?("1")
      assert row[1].has_text?("Status")
      assert row[1].has_text?("PUBLISHED")

      click_button("Create new edition")

      row = find_all(".govuk-summary-list__row")
      assert row[0].has_text?("Edition")
      assert row[0].has_text?("2")
      assert row[1].has_text?("Status")
      assert row[1].has_text?("DRAFT")
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
      fill_in "popular_links[1][url]", with: " www.abc.com "
      click_button("Save")

      assert page.has_text?("www.abc.com")
      assert_not page.has_text?(" www.abc.com ")
    end

    should "render create page when 'Cancel' is clicked" do
      click_link("Cancel")

      assert_current_path show_popular_links_path
    end

    should "not save any changes when 'Cancel' is clicked" do
      fill_in "popular_links[1][url]", with: "www.abc.com"
      click_link("Cancel")

      assert_not page.has_text?("www.abc.com")
    end
  end

  context "#publish" do
    setup do
      click_button("Create new edition")
    end

    should "publish latest edition when 'Publish' is clicked" do
      click_button("Publish")

      assert page.has_text?("PUBLISHED")
      assert page.has_text?("Popular links successfully published.")
    end
  end

  def visit_popular_links
    visit "/homepage/popular-links"
  end
end
