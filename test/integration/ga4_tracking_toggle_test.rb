require "integration_test_helper"

class Ga4TrackingToggleTest < IntegrationTest
  setup do
    FactoryBot.create(:user, :govuk_editor)
    @edition = FactoryBot.create(:edition)
  end

  context "'ga4_form_tracking' feature toggle is disabled" do
    setup do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:ga4_form_tracking, false)

      visit edition_path(@edition)
    end

    should "not call the 'ga4-form-setup' and 'ga4-index-section-setup' modules" do
      data_module = page.find("main")["data-module"].split(" ")

      assert_not data_module.include?("ga4-form-setup")
      assert_not data_module.include?("ga4-index-section-setup")
    end
  end

  context "'ga4_form_tracking' feature toggle is enabled" do
    setup do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:ga4_form_tracking, true)

      visit edition_path(@edition)
    end

    should "call the 'ga4-form-setup' and 'ga4-index-section-setup' modules" do
      data_module = page.find("main")["data-module"].split(" ")

      assert data_module.include?("ga4-form-setup")
      assert data_module.include?("ga4-index-section-setup")
    end
  end
end
