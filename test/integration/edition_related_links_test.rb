require "integration_test_helper"

class EditionRelatedLinksTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    login_as(@govuk_editor)
    @draft_edition = FactoryBot.create(:edition, :draft)

    visit edition_path(@draft_edition)
    click_link "Related external links"
  end

  should "render 'Related external links' header, inset text and save button" do
    assert page.has_css?("h2", text: "Related external links")
    assert page.has_css?("div.gem-c-inset-text", text: "After saving, changes to related external links will be visible on the site the next time this publication is published.")
    assert page.has_css?("button.gem-c-button", text: "Save")
  end

  context "Document has no external links when page loads" do
    setup do
      @draft_edition = FactoryBot.create(:edition, :draft)
      visit edition_path(@draft_edition)
      click_link "Related external links"
    end

    should "render an empty 'Add another' form" do
      assert page.has_css?("legend", text: "Link 1")
      assert_equal "Title", page.find("label[for='artefact_external_links_attributes_0_title']").text
      assert_equal "URL", page.find("label[for='artefact_external_links_attributes_0_url']").text
      assert_equal "", page.find("input[name='artefact[external_links_attributes][0][title]']").value
      assert_equal "", page.find("input[name='artefact[external_links_attributes][0][url]']").value
    end
  end

  context "Document already has external links when page loads" do
    setup do
      @draft_edition = FactoryBot.create(:edition, :draft)
      @draft_edition.artefact.external_links = [ArtefactExternalLink.build({ title: "Link One", url: "https://gov.uk" })]
      visit edition_path(@draft_edition)
      click_link "Related external links"
    end

    should "render a pre-populated 'Add another' form" do
      # Link 1
      assert page.has_css?("legend", text: "Link 1")
      assert page.has_css?("input[name='artefact[external_links_attributes][0][_destroy]']")
      assert_equal "Title", page.find("label[for='artefact_external_links_attributes_0_title']").text
      assert_equal "URL", page.find("label[for='artefact_external_links_attributes_0_url']").text
      assert_equal "Link One", page.find("input[name='artefact[external_links_attributes][0][title]']").value
      assert_equal "https://gov.uk", page.find("input[name='artefact[external_links_attributes][0][url]']").value

      # Link 2 (empty fields)
      assert page.has_css?("legend", text: "Link 2")
      assert_equal "Title", page.find("label[for='artefact_external_links_attributes_1_title']").text
      assert_equal "URL", page.find("label[for='artefact_external_links_attributes_1_url']").text
      assert_equal "", page.find("input[name='artefact[external_links_attributes][1][title]']").value
      assert_equal "", page.find("input[name='artefact[external_links_attributes][1][url]']").value
    end
  end

  context "User adds a new external link and saves" do
    setup do
      @draft_edition = FactoryBot.create(:edition, :draft)
      visit edition_path(@draft_edition)
      click_link "Related external links"
    end

    should "render a pre-populated 'Add another' form" do
      within :css, ".gem-c-add-another .js-add-another__empty" do
        fill_in "Title", with: "A new external link"
        fill_in "URL", with: "https://foo.com"
      end

      click_button("Save")

      # Link 1
      assert page.has_css?("legend", text: "Link 1")
      assert page.has_css?("input[name='artefact[external_links_attributes][0][_destroy]']")
      assert_equal "Title", page.find("label[for='artefact_external_links_attributes_0_title']").text
      assert_equal "URL", page.find("label[for='artefact_external_links_attributes_0_url']").text
      assert_equal "A new external link", page.find("input[name='artefact[external_links_attributes][0][title]']").value
      assert_equal "https://foo.com", page.find("input[name='artefact[external_links_attributes][0][url]']").value

      # Link 2 (empty fields)
      assert page.has_css?("legend", text: "Link 2")
      assert_equal "Title", page.find("label[for='artefact_external_links_attributes_1_title']").text
      assert_equal "URL", page.find("label[for='artefact_external_links_attributes_1_url']").text
      assert_equal "", page.find("input[name='artefact[external_links_attributes][1][title]']").value
      assert_equal "", page.find("input[name='artefact[external_links_attributes][1][url]']").value
    end
  end

  context "User deletes an external link and saves" do
    setup do
      @draft_edition = FactoryBot.create(:edition, :draft)
      @draft_edition.artefact.external_links = [ArtefactExternalLink.build({ title: "Link One", url: "https://gov.uk" })]
      visit edition_path(@draft_edition)
      click_link "Related external links"
    end

    should "render an empty 'Add another' form" do
      within :css, ".gem-c-add-another .js-add-another__fieldset:first-of-type" do
        check("Delete")
      end

      click_button("Save")

      assert page.has_css?("legend", text: "Link 1")
      assert_equal "Title", page.find("label[for='artefact_external_links_attributes_0_title']").text
      assert_equal "URL", page.find("label[for='artefact_external_links_attributes_0_url']").text
      assert_equal "", page.find("input[name='artefact[external_links_attributes][0][title]']").value
      assert_equal "", page.find("input[name='artefact[external_links_attributes][0][url]']").value
    end
  end
end
