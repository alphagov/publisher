# frozen_string_literal: true

require_relative "../integration_test_helper"

class RootOverviewTest < IntegrationTest
  setup do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_publications_filter, true)
  end

  should "be able to view different pages of results" do
    alice = FactoryBot.create(:user, :govuk_editor, name: "Alice", uid: "alice")
    FactoryBot.create(:guide_edition, title: "Guides and Gals", assigned_to: alice)
    FactoryBot.create_list(:guide_edition, FilteredEditionsPresenter::ITEMS_PER_PAGE, assigned_to: alice)

    visit "/"
    assert_content("21 document(s)")
    assert_no_content("Guides and Gals")

    click_on "Next"
    assert_content("21 document(s)")
    assert_content("Guides and Gals")

    click_on "Prev"
    assert_content("21 document(s)")
    assert_no_content("Guides and Gals")
  end
end
