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
    should "show new edition with draft status" do
      click_button("Create new edition")

      assert page.has_text?("Edition")
      assert page.has_text?(@popular_links.version_number)
      assert page.has_text?("Status")
      assert page.has_text?("DRAFT")
      assert page.has_css?(".govuk-tag--yellow")
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

  def visit_popular_links
    visit "/homepage/popular-links"
  end
end
