require "integration_test_helper"

class EditionEditJSTest < JavascriptIntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    login_as(@govuk_editor)
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_edit_phase_2, true)
    test_strategy.switch!(:design_system_edit_phase_3a, true)
  end

  context "Edit tab" do
    context "Unsaved changes validation prompt" do
      setup do
        visit_edit_page
      end

      should "leave the page with no alert when the user has not made changes to the form" do
        click_link("Metadata")
        assert_current_path metadata_edition_path(@edit_edition.id)
      end
    end

    context "guide edition" do
      setup do
        visit_draft_guide_edition_with_parts
      end

      context "reordering chapters" do
        setup do
          click_link "Reorder chapters"
        end

        should "reorder chapters and redirect to guide edit page when update order is clicked" do
          # Assert that javascript buttons change visible order for user
          within all(".gem-c-reorderable-list__item")[0] do
            assert page.has_text?("PART !")
            click_button("Down")
          end
          within all(".gem-c-reorderable-list__item")[1] do
            assert page.has_text?("PART !", wait: 1)
          end
          within all(".gem-c-reorderable-list__item")[0] do
            assert page.has_text?("PART !!", wait: 1)
          end

          click_button("Update order")

          assert page.has_content?("Chapter order updated")

          within all(".govuk-summary-list__row")[3] do
            assert page.has_text?("PART !!")
          end
          within all(".govuk-summary-list__row")[4] do
            assert page.has_text?("PART !")
          end
        end

        should "not reorder chapters and redirect to guide edit page when cancel is clicked" do
          within all(".gem-c-reorderable-list__item")[0] do
            assert page.has_text?("PART !")
            click_button("Down")
          end
          within all(".gem-c-reorderable-list__item")[1] do
            assert page.has_text?("PART !", wait: 1)
          end
          within all(".gem-c-reorderable-list__item")[0] do
            assert page.has_text?("PART !!", wait: 1)
          end

          click_link "Cancel"

          within all(".govuk-summary-list__row")[3] do
            assert page.has_text?("PART !")
          end
          within all(".govuk-summary-list__row")[4] do
            assert page.has_text?("PART !!")
          end
        end
      end
    end
  end

  context "Related external links tab" do
    setup do
      visit_related_external_links_page
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
        visit_related_external_links_page
        @external_links_edition.artefact.external_links = [ArtefactExternalLink.build({ title: "Link one", url: "https://one.com" })]
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

    context "Unsaved changes validation prompt" do
      should "leave the page with no alert when the user has not made changes to the form" do
        click_link("Metadata")
        assert_current_path metadata_edition_path(@external_links_edition.id)
      end
    end

    context "User does not have editor permissions" do
      setup do
        user = FactoryBot.create(:user, name: "Stub User")
        login_as(user)
        visit_related_external_links_page
        @external_links_edition.artefact.external_links = [ArtefactExternalLink.build({ title: "Link one", url: "https://one.com" })]
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

  context "Tag related content page" do
    setup do
      stub_linkables
      visit_tagging_related_content_page
    end

    should "render the 'Tag related content' page" do
      within :css, ".gem-c-heading" do
        assert page.has_css?("h1", text: "Tag related content")
        assert page.has_css?(".gem-c-heading__context", text: @tagging_edition.title)
      end

      assert page.has_text?("Related content items are displayed in the sidebar.")
      assert page.has_button?("Save")
      assert page.has_link?("Cancel")
    end

    should "redirect to tagging tab when Cancel link is clicked" do
      click_link("Cancel")

      assert_current_path tagging_edition_path(@tagging_edition.id)
    end

    context "Adding tags for a related content page" do
      should "render an empty Add Another form" do
        within :css, ".gem-c-add-another" do
          assert page.has_css?("legend", text: "Related content 1")
          assert page.has_css?("label", text: "URL or path")
          assert page.has_css?(".gem-c-hint", text: "For example, /pay-vat")
          assert page.has_css?(".govuk-input", count: 1)
          assert page.has_css?(".govuk-input[value='']", count: 1)
          assert page.has_css?("button", text: "Add another related content item")
        end
      end

      should "display an error when the form is submitted if a value entered is not a valid path" do
        Services.publishing_api.stubs(:lookup_content_ids).returns({ "/company-tax-returns" => "830e403b-7d81-45f1-8862-81dcd55b4ec7", "/prepare-file-annual-accounts-for-limited-company" => "5cb58486-0b00-4da8-8076-382e474b4f03" })
        fill_in "URL or path", with: "/invalid-path"

        click_button("Save")

        assert_current_path update_related_content_edition_path(@tagging_edition.id)
        assert page.has_text?("/invalid-path is not a known URL on GOV.UK, check URL or path is correctly entered.")
      end

      should "save the added 'Related content' tags when the form is submitted" do
        fill_in "URL or path", with: "/company-tax-returns"

        click_button("Save")

        assert page.has_text?("Related content updated")
        assert_requested :patch,
                         "#{Plek.find('publishing-api')}/v2/links/#{@tagging_edition.content_id}",
                         body: { "links": { "organisations": [],
                                            "mainstream_browse_pages": [],
                                            "ordered_related_items": %w[830e403b-7d81-45f1-8862-81dcd55b4ec7],
                                            "parent": [] },
                                 "previous_version": 0 }
        assert_current_path tagging_edition_path(@tagging_edition.id)
      end
    end

    context "Editing tags for a related content page" do
      setup do
        stub_linkables_with_data
        visit_tagging_related_content_page
      end

      should "render a pre-populated Add Another form" do
        within all(".js-add-another__fieldset")[0] do
          assert page.has_css?("legend", text: "Related content 1")
          assert page.has_css?("label", text: "URL or path")
          assert page.has_css?(".gem-c-hint", text: "For example, /pay-vat")
          assert page.has_css?("input[value='/company-tax-returns']")
          assert page.has_css?("button", text: "Delete")
        end

        within all(".js-add-another__fieldset")[1] do
          assert page.has_css?("legend", text: "Related content 2")
          assert page.has_css?("label", text: "URL or path")
          assert page.has_css?(".gem-c-hint", text: "For example, /pay-vat")
          assert page.has_css?("input[value='/prepare-file-annual-accounts-for-limited-company']")
          assert page.has_css?("button", text: "Delete")
        end

        within all(".js-add-another__fieldset")[2] do
          assert page.has_css?("legend", text: "Related content 3")
          assert page.has_css?("label", text: "URL or path")
          assert page.has_css?(".gem-c-hint", text: "For example, /pay-vat")
          assert page.has_css?("input[value='/corporation-tax']")
          assert page.has_css?("button", text: "Delete")
        end

        within all(".js-add-another__fieldset")[3] do
          assert page.has_css?("legend", text: "Related content 4")
          assert page.has_css?("label", text: "URL or path")
          assert page.has_css?(".gem-c-hint", text: "For example, /pay-vat")
          assert page.has_css?("input[value='/tax-help']")
          assert page.has_css?("button", text: "Delete")
        end
      end

      should "save deleted 'Related content' tags when the form is submitted" do
        within all(".js-add-another__fieldset")[3] do
          click_button("Delete")
        end
        within all(".js-add-another__fieldset")[1] do
          click_button("Delete")
        end
        click_button("Save")

        assert page.has_text?("Related content updated")
        assert_requested :patch,
                         "#{Plek.find('publishing-api')}/v2/links/#{@tagging_edition.content_id}",
                         body: { "links": { "organisations": %w[9a9111aa-1db8-4025-8dd2-e08ec3175e72],
                                            "mainstream_browse_pages": %w[CONTENT-ID-CAPITAL CONTENT-ID-RTI CONTENT-ID-VAT],
                                            "ordered_related_items": %w[830e403b-7d81-45f1-8862-81dcd55b4ec7 853feaf2-152c-4aa5-8edb-ba84a88860bf],
                                            "parent": %w[CONTENT-ID-CAPITAL] },
                                 "previous_version": 1 }
        assert_current_path tagging_edition_path(@tagging_edition.id)
      end
    end

    context "Reordering tags for a related content page" do
      setup do
        stub_linkables_with_data
        visit_tagging_reorder_related_content_page_edition_path
      end

      should "submit reordered tags when the form is submitted with changes" do
        # Assert that javascript buttons change visible order for user
        within all(".gem-c-reorderable-list__item")[0] do
          assert page.has_text?("/company-tax-returns")
          click_button("Down")
        end
        within all(".gem-c-reorderable-list__item")[1] do
          assert page.has_text?("/company-tax-returns", wait: 1)
        end
        within all(".gem-c-reorderable-list__item")[3] do
          assert page.has_text?("/tax-help")
          click_button("Up")
        end
        within all(".gem-c-reorderable-list__item")[2] do
          assert page.has_text?("/tax-help", wait: 1)
        end
        click_button("Update order")
        assert page.has_content?("Related content order updated")

        # Assert that updated order is submitted in http request
        assert_requested :patch,
                         "#{Plek.find('publishing-api')}/v2/links/#{@tagging_edition.content_id}",
                         body: { "links": { "organisations": %w[9a9111aa-1db8-4025-8dd2-e08ec3175e72],
                                            "mainstream_browse_pages": %w[CONTENT-ID-CAPITAL CONTENT-ID-RTI CONTENT-ID-VAT],
                                            "ordered_related_items": %w[5cb58486-0b00-4da8-8076-382e474b4f03 830e403b-7d81-45f1-8862-81dcd55b4ec7 91fef6f6-3a59-42ab-a14d-42c4e5eee1a1 853feaf2-152c-4aa5-8edb-ba84a88860bf],
                                            "parent": %w[CONTENT-ID-CAPITAL] },
                                 "previous_version": 1 }
        assert_current_path tagging_edition_path(@tagging_edition.id)
      end
    end
  end

  context "Metadata tab" do
    context "Unsaved changes validation prompt" do
      setup do
        visit_metadata_page
      end

      should "leave the page with no alert when the user has not made changes to the form" do
        click_link("Edit")
        assert_current_path edition_path(@edit_edition.id)
      end
    end
  end

private

  def visit_edit_page
    @edit_edition = FactoryBot.create(:guide_edition)
    visit edition_path(@edit_edition)
  end

  def visit_related_external_links_page
    @external_links_edition = FactoryBot.create(:guide_edition, title: "Edit page title", state: "draft", overview: "metatags", in_beta: 1)
    visit related_external_links_edition_path(@external_links_edition)
  end

  def visit_tagging_related_content_page
    @tagging_edition = FactoryBot.create(:guide_edition, title: "The edition to tag")
    visit tagging_related_content_page_edition_path(@tagging_edition)
  end

  def visit_tagging_reorder_related_content_page_edition_path
    @tagging_edition = FactoryBot.create(:guide_edition, title: "The edition to tag")
    visit tagging_reorder_related_content_page_edition_path(@tagging_edition)
  end

  def visit_draft_guide_edition_with_parts
    create_draft_guide_edition_with_parts
    visit edition_path(@draft_guide_edition_with_parts)
  end

  def create_draft_guide_edition_with_parts
    @draft_guide_edition_with_parts = FactoryBot.create(:guide_edition_with_two_parts, title: "Edit page title", state: "draft", overview: "metatags", in_beta: 1, hide_chapter_navigation: 1, panopticon_id: FactoryBot.create(:artefact).id)
  end

  def visit_metadata_page
    visit_edit_page
    click_link("Metadata")
  end
end
