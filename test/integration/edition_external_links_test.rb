require "integration_test_helper"

class EditionExternalLinksTest < JavascriptIntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    login_as(@govuk_editor)
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_edit, true)
  end

  context "Related external links tab" do
    setup do
      visit_draft_edition
      click_link "Related external links"
    end

    should "render 'Related external links' header, inset text and save button" do
      assert page.has_css?("h2", text: "Related external links")
      assert page.has_css?("div.gem-c-inset-text", text: "After saving, changes to related external links will be visible on the site the next time this publication is published.")
      assert page.has_css?("button.gem-c-button", text: "Save")
    end

    context "Edition does not already have related external links" do
      should "render an empty 'Add another' form when the page loads" do
        assert page.has_css?("legend", text: "Link 1")
        assert page.has_no_css?("input[name='artefact[external_links_attributes][0][_destroy]']")
        assert_equal "Title", page.find("label[for='artefact_external_links_attributes_0_title']").text
        assert_equal "URL", page.find("label[for='artefact_external_links_attributes_0_url']").text
        assert_equal "", page.find("input[name='artefact[external_links_attributes][0][title]']").value
        assert_equal "", page.find("input[name='artefact[external_links_attributes][0][url]']").value
        assert page.has_css?("button", text: "Add another link")
      end
    end

    context "Edition already has related external links" do
      setup do
        visit_draft_edition
        @draft_edition.artefact.external_links = [{ title: "Link one", url: "https://one.com" }]
        click_link "Related external links"
      end

      should "render a pre-populated 'Add another' form when the page loads" do
        assert page.has_css?("legend", text: "Link 1")
        assert page.has_no_css?("input[name='artefact[external_links_attributes][0][_destroy]']")
        assert_equal "Title", page.find("label[for='artefact_external_links_attributes_0_title']").text
        assert_equal "URL", page.find("label[for='artefact_external_links_attributes_0_url']").text
        assert_equal "Link one", page.find("input[name='artefact[external_links_attributes][0][title]']").value
        assert_equal "https://one.com", page.find("input[name='artefact[external_links_attributes][0][url]']").value
        assert page.has_css?("button", text: "Add another link")
      end
    end

    should "display 'Delete' buttons and a second set of inputs when 'Add another link' is clicked" do
      click_button("Add another link")

      assert page.has_css?("legend", text: "Link 1")
      assert page.has_no_css?("input[name='artefact[external_links_attributes][0][_destroy]']")
      assert_equal "Title", page.find("label[for='artefact_external_links_attributes_0_title']").text
      assert_equal "URL", page.find("label[for='artefact_external_links_attributes_0_url']").text
      assert_equal "", page.find("input[name='artefact[external_links_attributes][0][title]']").value
      assert_equal "", page.find("input[name='artefact[external_links_attributes][0][url]']").value
      assert page.has_css?("legend", text: "Link 2")
      assert page.has_no_css?("input[name='artefact[external_links_attributes][1][_destroy]']")
      assert_equal "Title", page.find("label[for='artefact_external_links_attributes_1_title']").text
      assert_equal "URL", page.find("label[for='artefact_external_links_attributes_1_url']").text
      assert_equal "", page.find("input[name='artefact[external_links_attributes][1][title]']").value
      assert_equal "", page.find("input[name='artefact[external_links_attributes][1][url]']").value
      assert page.has_css?("button", text: "Add another link")
      within :css, ".gem-c-add-another .js-add-another__fieldset:nth-of-type(1)" do
        assert page.has_css?("button", text: "Delete")
      end
      within :css, ".gem-c-add-another .js-add-another__fieldset:nth-of-type(2)" do
        assert page.has_css?("button", text: "Delete")
      end
    end

    should "delete the first set of fields when the user clicks the first “Delete” button" do
      click_button("Add another link")

      within :css, ".gem-c-add-another .js-add-another__fieldset:nth-of-type(1)" do
        click_button("Delete")
      end

      assert page.has_css?("legend", text: "Link 1")
      assert page.has_no_css?("label[for='artefact_external_links_attributes_0_title']")
      assert page.has_no_css?("label[for='artefact_external_links_attributes_0_url']")
      assert_equal "Title", page.find("label[for='artefact_external_links_attributes_1_title']").text
      assert_equal "URL", page.find("label[for='artefact_external_links_attributes_1_url']").text
      assert page.has_css?("button", text: "Add another link")
      within :css, ".gem-c-add-another .js-add-another__fieldset:nth-of-type(2)" do
        assert page.has_css?("button", text: "Delete")
      end
    end
  end

private

  def visit_draft_edition
    @draft_edition = FactoryBot.create(:edition, title: "Edit page title", state: "draft", overview: "metatags", in_beta: 1, body: "The body")
    visit edition_path(@draft_edition)
  end
end
