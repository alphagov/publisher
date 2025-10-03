require "integration_test_helper"

class Ga4TrackingTest < JavascriptIntegrationTest
  setup do
    FactoryBot.create(:user, :govuk_editor)

    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_publications_filter, true)
  end

  context "header" do
    should "render the correct ga4 data-attributes in the header section" do
      visit "/"

      assert page.has_css?("header[data-ga4-no-copy='true']")
    end
  end

  context "main" do
    should "render the correct ga4 data-attributes in the main content section" do
      visit "/"

      assert page.has_css?(".govuk-width-container[data-ga4-no-copy='true']")
    end
  end

  context "footer" do
    should "render the correct ga4 data-attributes in the footer section" do
      visit "/"

      assert page.has_css?("footer[data-ga4-no-copy='true']")
    end
  end
end
