require "integration_test_helper"

class Ga4TrackingTest < JavascriptIntegrationTest
  setup do
    FactoryBot.create(:user, :govuk_editor)

    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_publications_filter, true)
  end

  context "Edit page" do
    setup do
      edition = FactoryBot.create(:answer_edition, title: "Answer edition")
      visit edition_path(edition)
    end

    should "render the correct ga4 data-attributes on the form" do
      title_field = page.find("input[name='edition[title]']")
      metatag_field = page.find("textarea[name='edition[overview]']")
      body_field = page.find("textarea[name='edition[body]']")
      beta_field = page.find("fieldset")

      title_field_data = JSON.parse(title_field["data-ga4-index"])
      metatag_field_data = JSON.parse(metatag_field["data-ga4-index"])
      body_field_data = JSON.parse(body_field["data-ga4-index"])
      beta_field_data = JSON.parse(beta_field["data-ga4-index"])

      assert_equal title_field_data["index_section"], 0
      assert_equal title_field_data["index_section_count"], 4
      assert_equal metatag_field_data["index_section"], 1
      assert_equal metatag_field_data["index_section_count"], 4
      assert_equal body_field_data["index_section"], 2
      assert_equal body_field_data["index_section_count"], 4
      assert_equal beta_field_data["index_section"], 3
      assert_equal beta_field_data["index_section_count"], 4
    end
  end
end
