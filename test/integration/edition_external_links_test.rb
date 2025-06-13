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
      should "render the form containing just the 'Add related external link' button when the page loads" do
        assert page.has_no_css?("legend", text: "Link 1")
        assert page.has_no_css?("input[name='artefact[external_links_attributes][0][_destroy]']")
        assert page.has_no_css?("label[for='artefact_external_links_attributes_0_title']")
        assert page.has_no_css?("label[for='artefact_external_links_attributes_0_url']")
        assert page.has_no_css?("input[name='artefact[external_links_attributes][0][title]']")
        assert page.has_no_css?("input[name='artefact[external_links_attributes][0][url]']")
        assert page.has_css?("button", text: "Add related external link")
      end
    end

    context "Edition already has related external links" do
      setup do
        visit_draft_edition
        @draft_edition.artefact.external_links = [ArtefactExternalLink.build({ title: "Link one", url: "https://one.com" })]
        click_link "Related external links"
      end

      should "render a pre-populated 'Add another' form when the page loads" do
        assert page.has_css?("legend", text: "Link 1")
        assert page.has_no_css?("input[name='artefact[external_links_attributes][0][_destroy]']")
        assert_equal "Title", page.find("label[for='artefact_external_links_attributes_0_title']").text
        assert_equal "URL", page.find("label[for='artefact_external_links_attributes_0_url']").text
        assert_equal "Link one", page.find("input[name='artefact[external_links_attributes][0][title]']").value
        assert_equal "https://one.com", page.find("input[name='artefact[external_links_attributes][0][url]']").value
        assert page.has_css?("button", text: "Add related external link")
      end
    end

    should "display a 'Delete' button and a set of inputs when the Add button is clicked" do
      click_button("Add related external link")

      assert page.has_css?("legend", text: "Link 1")
      assert page.has_no_css?("input[name='artefact[external_links_attributes][0][_destroy]']")
      assert_equal "Title", page.find("label[for='artefact_external_links_attributes_0_title']").text
      assert_equal "URL", page.find("label[for='artefact_external_links_attributes_0_url']").text
      assert_equal "", page.find("input[name='artefact[external_links_attributes][0][title]']").value
      assert_equal "", page.find("input[name='artefact[external_links_attributes][0][url]']").value
      assert page.has_css?("button", text: "Add related external link")
      within :css, ".gem-c-add-another .js-add-another__fieldset" do
        assert page.has_css?("button", text: "Delete")
      end
    end

    should "delete the set of fields when the user clicks the 'Delete' button" do
      click_button("Add related external link")

      within :css, ".gem-c-add-another .js-add-another__fieldset" do
        click_button("Delete")
      end

      assert page.has_no_css?("legend", text: "Link 1")
      assert page.has_no_css?("label[for='artefact_external_links_attributes_0_title']")
      assert page.has_no_css?("label[for='artefact_external_links_attributes_0_url']")
      assert page.has_no_css?("label[for='artefact_external_links_attributes_1_title']")
      assert page.has_no_css?("label[for='artefact_external_links_attributes_1_url']")
      assert page.has_css?("button", text: "Add related external link")
    end

    context "User does not have editor permissions" do
      setup do
        user = FactoryBot.create(:user, name: "Stub User")
        login_as(user)
        visit_draft_edition
        link = { title: "Link one", url: "https://one.com" }
        @draft_edition.artefact.external_links = [ArtefactExternalLink.build(link)]
        click_link "Related external links"
      end

      should "not have access to the editor actions" do
        assert page.has_no_css?("button", text: "Delete")
        assert page.has_no_css?("button", text: "Add related external link")
        assert page.has_no_css?("button", text: "Save")
        assert page.has_no_text?("After saving, changes to related external links will be visible on the site the next time this publication is published.")
      end

      should "see a read only version of the eternal links" do
        assert page.has_css?("h3", text: "Link one")
        assert page.has_css?(".govuk-body", text: "https://one.com")
      end
    end
  end

private

  def visit_draft_edition
    @draft_edition = FactoryBot.create(:edition, title: "Edit page title", state: "draft", overview: "metatags", in_beta: 1, body: "The body")
    visit edition_path(@draft_edition)
  end
end
