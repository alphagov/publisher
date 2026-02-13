require "integration_test_helper"

class AddArtefactJsTest < JavascriptIntegrationTest
  setup do
    setup_users
    @test_strategy.switch!(:design_system_edit_phase_3b, true)
    @test_strategy.switch!(:design_system_edit_phase_4, true)
  end

  context "auto-population of an artefact's slug from its title when JS is enabled" do
    should "auto-populate the artefact's slug from the title" do
      visit root_path
      click_link "Create new content"
      choose "Answer", allow_label_click: true
      click_button "Continue"
      fill_in "Title", with: "Example title"
      find_field("Title").send_keys(:tab)

      assert page.has_field?("Slug", with: "example-title")
    end
  end
end
