require "integration_test_helper"

class HomepagePopularLinksTest < JavascriptIntegrationTest
  setup do
    setup_users
    @popular_links = FactoryBot.create(:popular_links)
    visit_popular_links
  end

  should "show page title" do
    assert_title "Popular on GOV.UK"
  end

  should "show 'Homepage' as a page title context" do
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
    assert page.has_text?("DRAFT")
    assert page.has_css?(".govuk-tag--yellow")
  end

  def visit_popular_links
    visit "/homepage/popular-links"
  end
end
