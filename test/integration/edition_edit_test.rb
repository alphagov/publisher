require "integration_test_helper"

class EditionEditTest < IntegrationTest
  setup do
    setup_users
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_edit, true)
    stub_linkables
  end

  should "show document summary and title" do
    edition = FactoryBot.create(:guide_edition, title: "Edit page title", state: "draft")
    visit edition_path(edition)

    assert page.has_title?("Edit page title")

    row = find_all(".govuk-summary-list__row")
    assert row[0].has_content?("Assigned to")
    assert row[1].has_text?("Content type")
    assert row[1].has_text?("Guide")
    assert row[2].has_text?("Edition")
    assert row[2].has_text?("1")
    assert row[2].has_text?("Draft")
  end
end
