require "integration_test_helper"

class Ga4TrackingTest < JavascriptIntegrationTest
  setup do
    FactoryBot.create(:user, :govuk_editor)

    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_publications_filter, true)
  end

  should "render the correct ga4 data-attributes on page load]" do
    visit "/"

    assert page.has_css?("header[data-ga4-no-copy='true']")
    assert page.has_css?("footer[data-ga4-no-copy='true']")
    assert page.has_css?(".govuk-width-container[data-ga4-no-copy='true']")
  end

  context "Publications page" do
    should "render the correct ga4 data-attributes" do
      visit "/"

      assert page.has_css?(".govuk-width-container[data-ga4-filter-type='Publications']")
      assert page.has_css?(".govuk-width-container[data-module='ga4-event-tracker ga4-index-section-setup ga4-paste-tracker ga4-link-tracker ga4-button-setup']")
    end
  end
end
