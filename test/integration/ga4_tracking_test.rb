require "integration_test_helper"

class Ga4TrackingTest < JavascriptIntegrationTest
  setup do
    FactoryBot.create(:user, :govuk_editor)

    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_publications_filter, true)
  end

  should "render the correct ga4 data-attributes on page load" do
    skip("Probably only want to test attributes and values added by setup scripts")

    visit "/"

    assert page.has_css?("header[data-ga4-no-copy='true']")
    assert page.has_css?("footer[data-ga4-no-copy='true']")
    assert page.has_css?(".govuk-width-container[data-ga4-no-copy='true']")
  end

  context "Publications page" do
    setup do
      @edition_1 = FactoryBot.create(:answer_edition, title: "The first document")
      @edition_2 = FactoryBot.create(:edition, title: "The second document")
    end

    should "add the corect GA4 parameters to the filter section" do
      visit "/"

      within ".publications-filter" do
        assert page.has_css?("input[name='search_text'][data-ga4-filter-parent='true'][data-ga4-index-section='1'][data-ga4-index='{\"index_section\":1,\"index_section_count\":4}']")
        assert page.has_css?("select[name='assignee_filter'][data-ga4-change-category='update-filter select'][data-ga4-filter-parent='true'][data-ga4-section='Assigned to'][data-ga4-index-section='2'][data-ga4-index='{\"index_section\":2,\"index_section_count\":4}']")
        assert page.has_css?("select[name='content_type_filter'][data-ga4-change-category='update-filter select'][data-ga4-filter-parent='true'][data-ga4-section='Content type'][data-ga4-index-section='3'][data-ga4-index='{\"index_section\":3,\"index_section_count\":4}']")
        assert page.has_css?("fieldset[data-ga4-index-section='4'][data-ga4-filter-parent='true'][data-ga4-index='{\"index_section\":4,\"index_section_count\":4}']")
        assert page.has_css?("button[data-ga4-event='{\"event_name\":\"select_content\",\"type\":\"button\",\"text\":\"Search\"}']", text: "Search")
        assert page.has_css?("a[data-ga4-link='{\"action\":\"reset\",\"event_name\":\"select_content\",\"type\":\"Publications\"}']", text: "Reset all fields")
      end
    end

    should "add the corect GA4 parameters to the table section" do
      skip("WIP")
      visit "/"

      within ".publications-table" do
        assert page.has_css?("a[data-ga4-link='{\"action\":\"opened\",\"event_name\":\"select_content\",\"type\":\"Publications\"}']", text: "Expand all")

        within :css, "table" do
          within :css, ".govuk-table__body" do
            within all(".govuk-table__row")[0] do
              assert page.has_css?("a[data-ga4-ecommerce-content-id='38a10b65-1376-4572-a322-841bcfc03575'][data-ga4-ecommerce-path='http://publisher.dev.gov.uk/editions/38a10b65-1376-4572-a322-841bcfc03575'][data-ga4-ecommerce-index='1']", text: @edition_1.title)
            end
          end
        end
      end
    end

    should "render the correct ga4 data-attributes" do
      skip("Probably only want to test attributes and values added by setup scripts")

      visit "/"

      assert page.has_css?(".govuk-width-container[data-ga4-filter-type='Publications']")
      assert page.has_css?(".govuk-width-container[data-module='ga4-event-tracker ga4-index-section-setup ga4-paste-tracker ga4-link-tracker ga4-button-setup']")
    end
  end
end
