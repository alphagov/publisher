require "integration_test_helper"

class EditionTaggingTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    login_as(@govuk_editor)
    @test_strategy = Flipflop::FeatureSet.current.test!
    @test_strategy.switch!(:design_system_edit_phase_3a, true)
    stub_linkables
  end

  context "tagging tab" do
    context "No tagging is set" do
      setup do
        @draft_edition = FactoryBot.create(:edition, :draft)
        visit edition_path(@draft_edition)
        click_link("Tagging")
      end

      should "show 'Tagging' header" do
        within :css, ".gem-c-heading h2" do
          assert page.has_text?("Tagging")
        end
      end

      should "show empty 'GOV.UK breadcrumb' summary in first position" do
        within all(".govuk-summary-card")[0] do
          assert page.has_text?("GOV.UK breadcrumb")
          assert page.has_text?("No breadcrumb set")
          assert page.has_link?("Set GOV.UK breadcrumb")
        end
      end

      should "show empty 'Mainstream browse pages' summary in second position" do
        within all(".govuk-summary-card")[1] do
          assert page.has_text?("Mainstream browse pages")
          assert page.has_text?("Not tagged to any browse pages")
          assert page.has_link?("Tag to a browse page")
        end
      end

      should "show empty 'Organisations' summary in third position" do
        within all(".govuk-summary-card")[2] do
          assert page.has_text?("Organisations")
          assert page.has_text?("Not tagged to any organisations")
          assert page.has_link?("Tag to an organisation")
        end
      end

      should "show empty 'Related content' summary in fourth position" do
        within all(".govuk-summary-card")[3] do
          assert page.has_text?("Related content")
          assert page.has_text?("Not tagged to any related content")
          assert page.has_link?("Tag to related content")
        end
      end

      should "not show 'Reorder' button in 'Related Content' when no related content items are present" do
        within all(".govuk-summary-card")[3] do
          assert page.has_no_text?("Reorder")
        end
      end

      context "User does not have correct permissions" do
        setup do
          user = FactoryBot.create(:user, name: "Stub User")
          login_as(user)
          visit edition_path(@draft_edition)
          click_link("Tagging")
        end

        should "not show the 'Tag to a browse page' link" do
          within all(".govuk-summary-card")[1] do
            assert page.has_no_link?("Tag to a browse page")
          end
        end

        should "not show the 'Tag to organisations page' link" do
          within all(".govuk-summary-card")[2] do
            assert page.has_no_link?("Tag to an organisation")
          end
        end

        should "not show the 'Tag to related content' link" do
          within all(".govuk-summary-card")[3] do
            assert page.has_no_link?("Tag to related content")
          end
        end
      end
    end

    context "Tagging is set" do
      setup do
        stub_linkables_with_data
        @draft_edition = FactoryBot.create(:edition, :draft)
        visit edition_path(@draft_edition)
        click_link("Tagging")
      end

      should "show 'GOV.UK breadcrumb' summary card in first position" do
        within all(".gem-c-summary-card")[0] do
          assert page.has_text?("GOV.UK breadcrumb")
          assert page.has_css?("dt", text: "Breadcrumb")
          assert page.has_css?("dt", text: "Tax > Capital Gains Tax")
        end
      end

      should "show 'Mainstream browse pages' summary card in second position" do
        within all(".gem-c-summary-card")[1] do
          assert page.has_text?("Mainstream browse pages")

          within all(".govuk-summary-list__row")[0] do
            assert page.has_css?("dt", text: "Browse page 1")
            assert page.has_css?("dt", text: "Tax > Capital Gains Tax")
          end

          within all(".govuk-summary-list__row")[1] do
            assert page.has_css?("dt", text: "Browse page 2")
            assert page.has_css?("dt", text: "Tax > RTI (draft)")
          end

          within all(".govuk-summary-list__row")[2] do
            assert page.has_css?("dt", text: "Browse page 3")
            assert page.has_css?("dt", text: "Tax > VAT")
          end
        end
      end

      should "show 'Organisations' summary card in third position" do
        within all(".gem-c-summary-card")[2] do
          assert page.has_text?("Organisations")

          within all(".govuk-summary-list__row")[0] do
            assert page.has_css?("dt", text: "Organisation")
            assert page.has_css?("dt", text: "Student Loans Company")
          end
        end
      end

      should "show 'Related content' summary card in fourth position" do
        within all(".gem-c-summary-card")[3] do
          assert page.has_text?("Related content")
          assert page.has_no_link?("Tag to related content")

          within all(".govuk-summary-list__row")[0] do
            assert page.has_css?("dt", text: "Related content 1")
            assert page.has_css?("dt", text: "/company-tax-returns")
          end

          within all(".govuk-summary-list__row")[1] do
            assert page.has_css?("dt", text: "Related content 2")
            assert page.has_css?("dt", text: "/prepare-file-annual-accounts-for-limited-company")
          end

          within all(".govuk-summary-list__row")[2] do
            assert page.has_css?("dt", text: "Related content 3")
            assert page.has_css?("dt", text: "/corporation-tax")
          end

          within all(".govuk-summary-list__row")[3] do
            assert page.has_css?("dt", text: "Related content 4")
            assert page.has_css?("dt", text: "/tax-help")
          end
        end
      end

      context "User has permissions" do
        should "show 'Edit' link on 'GOV.UK breadcrumb' summary card when user has permissions" do
          within all(".gem-c-summary-card")[0] do
            assert page.has_link?("Edit")
          end
        end

        should "navigate to the 'Set GOV.UK breadcrumb' page when the 'Edit' link is clicked" do
          within all(".gem-c-summary-card")[0] do
            click_link("Edit")
            assert_current_path tagging_breadcrumb_page_edition_path(@draft_edition)
          end
        end

        should "show 'Remove' link on 'GOV.UK breadcrumb' summary card when user has permissions" do
          within all(".gem-c-summary-card")[0] do
            assert page.has_link?("Remove")
          end
        end

        should "navigate to the remove breadcrumb page when the 'Remove' link is clicked" do
          within all(".gem-c-summary-card")[0] do
            click_link("Remove")
            assert_current_path tagging_remove_breadcrumb_page_edition_path(@draft_edition)
          end
        end

        should "show 'Edit' link on 'Mainstream browse pages' summary card when user has permissions" do
          within all(".gem-c-summary-card")[1] do
            assert page.has_link?("Edit")
          end
        end

        should "navigate to the 'Tag browse pages' page when the 'Edit' link is clicked" do
          within all(".gem-c-summary-card")[1] do
            click_link("Edit")
            assert_current_path tagging_mainstream_browse_pages_page_edition_path(@draft_edition)
          end
        end

        should "show 'Edit' link on 'Organisations' summary card when user has permissions" do
          within all(".gem-c-summary-card")[2] do
            assert page.has_link?("Edit")
          end
        end

        should "navigate to the 'Tag organisations' page when the 'Edit' link is clicked" do
          within all(".gem-c-summary-card")[2] do
            click_link("Edit")
            assert_current_path tagging_organisations_page_edition_path(@draft_edition)
          end
        end

        should "show 'Edit' link on 'Related content' summary card when user has permissions" do
          within all(".gem-c-summary-card")[3] do
            assert page.has_link?("Edit")
          end
        end

        should "navigate to the 'Tag related content' page when the 'Edit' link is clicked" do
          within all(".gem-c-summary-card")[3] do
            click_link("Edit")
            assert_current_path tagging_related_content_page_edition_path(@draft_edition)
          end
        end

        should "show 'Reorder' link on 'Related content' summary card when user has permissions" do
          within all(".gem-c-summary-card")[3] do
            assert page.has_link?("Reorder")
          end
        end

        should "navigate to the 'Reorder related content' page when the 'Reorder' link is clicked" do
          within all(".gem-c-summary-card")[3] do
            click_link("Reorder")
            assert_current_path tagging_reorder_related_content_page_edition_path(@draft_edition)
          end
        end
      end

      context "User does not have permissions" do
        setup do
          user = FactoryBot.create(:user, name: "Stub User")
          login_as(user)
          visit edition_path(@draft_edition)
          click_link("Tagging")
        end

        should "not show 'Edit' link on 'Mainstream browse pages' summary card when user does not have permissions" do
          within all(".gem-c-summary-card")[1] do
            assert page.has_no_link?("Edit")
          end
        end

        should "not show 'Edit' link on 'Organisations' summary card when user does not have permissions" do
          within all(".gem-c-summary-card")[2] do
            assert page.has_no_link?("Edit")
          end
        end

        should "not show 'Edit' link on 'Related content' summary card when user does not have permissions" do
          within all(".gem-c-summary-card")[3] do
            assert page.has_no_link?("Edit")
          end
        end

        should "not show 'Reorder' link on 'Related content' summary card when user does not have permissions" do
          within all(".gem-c-summary-card")[3] do
            assert page.has_no_link?("Reorder")
          end
        end
      end
    end

    context "minimal tagging is present" do
      should "not show 'Reorder' link on 'Related content' summary card when only one related content item is present" do
        stub_linkables_with_single_related_item
        draft_edition = FactoryBot.create(:edition, :draft)

        visit edition_path(draft_edition)
        click_link("Tagging")

        within all(".gem-c-summary-card")[3] do
          assert page.has_link?("Edit")
          assert page.has_no_link?("Reorder")
        end
      end
    end
  end

  context "Breadcrumb page" do
    setup do
      @draft_edition = FactoryBot.create(:edition, :draft)
    end

    context "Setting a breadcrumb" do
      setup do
        visit edition_path(@draft_edition)
        click_link("Tagging")
        click_link("Set GOV.UK breadcrumb")
      end

      should "redirect to tagging tab when Cancel link is clicked" do
        click_link("Cancel")
        assert_current_path tagging_edition_path(@draft_edition.id)
      end

      should "show the 'Set GOV.UK breadcrumb' page" do
        assert page.has_text?(@draft_edition.title)
        assert page.has_text?("Set GOV.UK breadcrumb")
        assert page.has_text?("Select the browse page you want to appear in the breadcrumb")
        assert page.has_element?("legend", text: "Tax")
        assert page.has_unchecked_field?("Capital Gains Tax")
        assert page.has_unchecked_field?("RTI (draft)")
        assert page.has_unchecked_field?("VAT")
        assert page.has_element?("legend", text: "Benefits")
        assert page.has_unchecked_field?("Benefits and financial support for families")
        assert page.has_unchecked_field?("Benefits and financial support if you're caring for someone")
        assert page.has_unchecked_field?("Benefits and financial support if you're disabled or have a health condition")
        assert page.has_text?("Options")
        assert page.has_button?("Save")
        assert page.has_link?("Cancel")
      end

      should "save the selected breadcrumb when the form is submitted" do
        choose("Capital Gains Tax")
        click_button("Save")

        assert_requested :patch,
                         "#{Plek.find('publishing-api')}/v2/links/#{@draft_edition.content_id}",
                         body: { "links": { "organisations": [],
                                            "mainstream_browse_pages": [],
                                            "ordered_related_items": [],
                                            "parent": %w[CONTENT-ID-CAPITAL] },
                                 "previous_version": 0 }
        assert_current_path tagging_edition_path(@draft_edition.id)
        assert page.has_text?("GOV.UK breadcrumbs updated")
      end
    end

    context "Editing a breadcrumb" do
      setup do
        stub_linkables_with_data
        visit edition_path(@draft_edition)
        click_link("Tagging")
        within all(".gem-c-summary-card")[0] do
          click_link("Edit")
        end
      end

      should "redirect to tagging tab when Cancel link is clicked" do
        click_link("Cancel")
        assert_current_path tagging_edition_path(@draft_edition.id)
      end

      should "show the 'Set GOV.UK breadcrumb' page with preselected radio" do
        assert page.has_text?(@draft_edition.title)
        assert page.has_text?("Set GOV.UK breadcrumb")
        assert page.has_text?("Select the browse page you want to appear in the breadcrumb")
        assert page.has_element?("legend", text: "Tax")
        assert page.has_checked_field?("Capital Gains Tax")
        assert page.has_unchecked_field?("RTI (draft)")
        assert page.has_unchecked_field?("VAT")
        assert page.has_element?("legend", text: "Benefits")
        assert page.has_unchecked_field?("Benefits and financial support for families")
        assert page.has_unchecked_field?("Benefits and financial support if you're caring for someone")
        assert page.has_unchecked_field?("Benefits and financial support if you're disabled or have a health condition")
        assert page.has_text?("Options")
        assert page.has_button?("Save")
        assert page.has_link?("Cancel")
      end

      should "update the breadcrumb when the form is submitted" do
        choose("VAT")
        click_button("Save")

        assert_requested :patch,
                         "#{Plek.find('publishing-api')}/v2/links/#{@draft_edition.content_id}",
                         body: { "links": { "organisations": %w[9a9111aa-1db8-4025-8dd2-e08ec3175e72],
                                            "mainstream_browse_pages": %w[CONTENT-ID-CAPITAL CONTENT-ID-RTI CONTENT-ID-VAT],
                                            "ordered_related_items": %w[830e403b-7d81-45f1-8862-81dcd55b4ec7 5cb58486-0b00-4da8-8076-382e474b4f03 853feaf2-152c-4aa5-8edb-ba84a88860bf 91fef6f6-3a59-42ab-a14d-42c4e5eee1a1],
                                            "parent": %w[CONTENT-ID-VAT] },
                                 "previous_version": 1 }
        assert_current_path tagging_edition_path(@draft_edition.id)
        assert page.has_text?("GOV.UK breadcrumbs updated")
      end
    end

    context "Removing a breadcrumb" do
      setup do
        stub_linkables_with_data
        visit edition_path(@draft_edition)
        click_link("Tagging")
        within all(".gem-c-summary-card")[0] do
          click_link("Remove")
        end
      end

      should "show the remove breadcrumb page " do
        assert page.has_text?(@draft_edition.title)
        assert page.has_text?("Are you sure you want to remove the breadcrumb?")
        assert page.has_text?("Breadcrumbs are displayed at the top of the page and help users to navigate. There may be some situations where you do not need a breadcrumb to display (for example, on Welsh translation pages).")
        assert page.has_unchecked_field?("Yes, remove the breadcrumb")
        assert page.has_unchecked_field?("No, keep the breadcrumb")
        assert page.has_button?("Save")
        assert page.has_link?("Cancel")
      end

      should "remove the breadcrumb when the form is submitted if the user selects 'Yes'" do
        choose("Yes, remove the breadcrumb")
        click_button("Save")

        assert_requested :patch,
                         "#{Plek.find('publishing-api')}/v2/links/#{@draft_edition.content_id}",
                         body: { "links": { "organisations": %w[9a9111aa-1db8-4025-8dd2-e08ec3175e72],
                                            "mainstream_browse_pages": %w[CONTENT-ID-CAPITAL CONTENT-ID-RTI CONTENT-ID-VAT],
                                            "ordered_related_items": %w[830e403b-7d81-45f1-8862-81dcd55b4ec7 5cb58486-0b00-4da8-8076-382e474b4f03 853feaf2-152c-4aa5-8edb-ba84a88860bf 91fef6f6-3a59-42ab-a14d-42c4e5eee1a1],
                                            "parent": [] },
                                 "previous_version": 1 }
        assert_current_path tagging_edition_path(@draft_edition.id)
        assert page.has_text?("GOV.UK breadcrumb removed")
      end

      should "retain the breadcrumb when the form is submitted if the user selects 'No'" do
        choose("No, keep the breadcrumb")
        click_button("Save")

        assert_current_path tagging_edition_path(@draft_edition.id)
        within all(".govuk-summary-card")[0] do
          assert page.has_text?("GOV.UK breadcrumb")
          assert page.has_css?("dt", text: "Breadcrumb")
          assert page.has_css?("dt", text: "Tax > Capital Gains Tax")
        end
      end

      should "display an error if the user tries to save with no option selected" do
        click_button("Save")
        assert page.has_text?("Select an option")
      end

      should "redirect to tagging tab when Cancel link is clicked" do
        click_link("Cancel")
        assert_current_path tagging_edition_path(@draft_edition.id)
      end
    end
  end

  context "Mainstream browse pages page" do
    setup do
      @draft_edition = FactoryBot.create(:edition, :draft)
      visit edition_path(@draft_edition)
      click_link("Tagging")
    end

    context "Adding Tags to a browse page" do
      setup do
        click_link("Tag to a browse page")
      end

      should "show the 'Tag to a browse page' page" do
        assert page.has_text?(@draft_edition.title)
        assert page.has_text?("Tag browse pages")
        assert page.has_text?("Select all that apply")
        assert page.has_element?("legend", text: "Tax")
        assert page.has_unchecked_field?("Capital Gains Tax")
        assert page.has_unchecked_field?("RTI (draft)")
        assert page.has_unchecked_field?("VAT")
        assert page.has_element?("legend", text: "Benefits")
        assert page.has_unchecked_field?("Benefits and financial support for families")
        assert page.has_unchecked_field?("Benefits and financial support if you're caring for someone")
        assert page.has_unchecked_field?("Benefits and financial support if you're disabled or have a health condition")
        assert page.has_text?("Options")
        assert page.has_button?("Save")
        assert page.has_link?("Cancel")
      end

      should "redirect to tagging tab when Cancel link is clicked" do
        click_link("Cancel")
        assert_current_path tagging_edition_path(@draft_edition.id)
      end

      should "save the selected tags to the browse page when the form is submitted" do
        check("Capital Gains Tax")
        click_button("Save")

        assert_requested :patch,
                         "#{Plek.find('publishing-api')}/v2/links/#{@draft_edition.content_id}",
                         body: { "links": { "organisations": [],
                                            "mainstream_browse_pages": %w[CONTENT-ID-CAPITAL],
                                            "ordered_related_items": [],
                                            "parent": [] },
                                 "previous_version": 0 }
        assert_current_path tagging_edition_path(@draft_edition.id)
        assert page.has_text?("Mainstream browse pages updated")
      end
    end

    context "Editing tags for a browse page" do
      setup do
        stub_linkables_with_data
        visit edition_path(@draft_edition)
        click_link("Tagging")
        within all(".gem-c-summary-card")[1] do
          click_link("Edit")
        end
      end

      should "show the 'Tag to a browse page' page with preselected options" do
        assert page.has_text?(@draft_edition.title)
        assert page.has_text?("Tag browse pages")
        assert page.has_text?("Select all that apply")
        assert page.has_element?("legend", text: "Tax")
        assert page.has_checked_field?("Capital Gains Tax")
        assert page.has_checked_field?("RTI (draft)")
        assert page.has_checked_field?("VAT")
        assert page.has_element?("legend", text: "Benefits")
        assert page.has_unchecked_field?("Benefits and financial support for families")
        assert page.has_unchecked_field?("Benefits and financial support if you're caring for someone")
        assert page.has_unchecked_field?("Benefits and financial support if you're disabled or have a health condition")
        assert page.has_button?("Save")
        assert page.has_link?("Cancel")
      end

      should "update the tags for the browse page when the form is submitted" do
        uncheck("RTI (draft)")
        uncheck("VAT")
        check("Benefits and financial support for families")
        click_button("Save")

        assert_requested :patch,
                         "#{Plek.find('publishing-api')}/v2/links/#{@draft_edition.content_id}",
                         body: { "links": { "organisations": %w[9a9111aa-1db8-4025-8dd2-e08ec3175e72],
                                            "mainstream_browse_pages": %w[CONTENT-ID-FAMILIES CONTENT-ID-CAPITAL],
                                            "ordered_related_items": %w[830e403b-7d81-45f1-8862-81dcd55b4ec7 5cb58486-0b00-4da8-8076-382e474b4f03 853feaf2-152c-4aa5-8edb-ba84a88860bf 91fef6f6-3a59-42ab-a14d-42c4e5eee1a1],
                                            "parent": %w[CONTENT-ID-CAPITAL] },
                                 "previous_version": 1 }
        assert_current_path tagging_edition_path(@draft_edition.id)
        assert page.has_text?("Mainstream browse pages updated")
      end
    end
  end

  context "Tag organisations page" do
    setup do
      @draft_edition = FactoryBot.create(:edition, :draft)
      visit tagging_organisations_page_edition_path(@draft_edition)
    end

    should "render the 'Tag organisations' page" do
      within :css, ".gem-c-heading" do
        assert page.has_css?("h1", text: "Tag organisations")
        assert page.has_css?(".gem-c-heading__context", text: @draft_edition.title)
      end

      assert page.has_text?("Tagging a page to an organisation makes it appear in searches filtered by that organisation.")
      assert page.has_text?("For example, a search for documents published by HMRC.")
      assert page.has_button?("Save")
      assert page.has_link?("Cancel")
    end

    should "redirect to tagging tab when Cancel link is clicked" do
      click_link("Cancel")
      assert_current_path tagging_edition_path(@draft_edition.id)
    end

    context "Adding tags for an organisations page" do
      should "render an empty Organisations form" do
        within :css, ".gem-c-select-with-search" do
          assert page.has_css?("label", text: "Organisations")
          assert page.has_css?("select")
        end
      end

      should "save the added 'Organisations' tags when the form is submitted" do
        select "Student Loans Company", from: "Organisations"
        click_button("Save")

        assert_requested :patch,
                         "#{Plek.find('publishing-api')}/v2/links/#{@draft_edition.content_id}",
                         body: { "links": { "organisations": %w[9a9111aa-1db8-4025-8dd2-e08ec3175e72],
                                            "mainstream_browse_pages": [],
                                            "ordered_related_items": [],
                                            "parent": [] },
                                 "previous_version": 0 }
        assert_current_path tagging_edition_path(@draft_edition.id)
        assert page.has_text?("Organisations updated")
      end
    end

    context "Editing tags for an organisations page" do
      setup do
        stub_linkables_with_data
        visit tagging_organisations_page_edition_path(@draft_edition)
      end

      should "render a pre-populated Organisations form" do
        within :css, "select" do
          assert find("option[value='9a9111aa-1db8-4025-8dd2-e08ec3175e72']").selected?
        end
      end

      should "delete 'Organisations' tags when the form is submitted" do
        page.unselect "Student Loans Company", from: "Organisations"
        click_button("Save")

        assert_requested :patch,
                         "#{Plek.find('publishing-api')}/v2/links/#{@draft_edition.content_id}",
                         body: { "links": { "organisations": [],
                                            "mainstream_browse_pages": %w[CONTENT-ID-CAPITAL CONTENT-ID-RTI CONTENT-ID-VAT],
                                            "ordered_related_items": %w[830e403b-7d81-45f1-8862-81dcd55b4ec7 5cb58486-0b00-4da8-8076-382e474b4f03 853feaf2-152c-4aa5-8edb-ba84a88860bf 91fef6f6-3a59-42ab-a14d-42c4e5eee1a1],
                                            "parent": %w[CONTENT-ID-CAPITAL] },
                                 "previous_version": 1 }
        assert_current_path tagging_edition_path(@draft_edition.id)
        assert page.has_text?("Organisations updated")
      end

      should "add 'Organisations' tags when the form is submitted" do
        page.select "Department for Education", from: "Organisations"
        click_button("Save")

        assert_requested :patch,
                         "#{Plek.find('publishing-api')}/v2/links/#{@draft_edition.content_id}",
                         body: { "links": { "organisations": %w[ebd15ade-73b2-4eaf-b1c3-43034a42eb37 9a9111aa-1db8-4025-8dd2-e08ec3175e72],
                                            "mainstream_browse_pages": %w[CONTENT-ID-CAPITAL CONTENT-ID-RTI CONTENT-ID-VAT],
                                            "ordered_related_items": %w[830e403b-7d81-45f1-8862-81dcd55b4ec7 5cb58486-0b00-4da8-8076-382e474b4f03 853feaf2-152c-4aa5-8edb-ba84a88860bf 91fef6f6-3a59-42ab-a14d-42c4e5eee1a1],
                                            "parent": %w[CONTENT-ID-CAPITAL] },
                                 "previous_version": 1 }
        assert_current_path tagging_edition_path(@draft_edition.id)
        assert page.has_text?("Organisations updated")
      end
    end
  end

  context "Tag related content page" do
    setup do
      @draft_edition = FactoryBot.create(:edition, :draft)
      visit tagging_related_content_page_edition_path(@draft_edition)
    end

    should "render the 'Tag related content' page" do
      within :css, ".gem-c-heading" do
        assert page.has_css?("h1", text: "Tag related content")
        assert page.has_css?(".gem-c-heading__context", text: @draft_edition.title)
      end

      assert page.has_text?("Related content items are displayed in the sidebar.")
      assert page.has_button?("Save")
      assert page.has_link?("Cancel")
    end

    context "Adding tags for a related content page" do
      should "render an empty Add Another form" do
        within :css, ".gem-c-add-another" do
          assert page.has_css?("legend", text: "Related content 1")
          assert page.has_css?("label", text: "URL or path")
          assert page.has_css?(".gem-c-hint", text: "For example, /pay-vat")
          assert page.has_css?(".govuk-input", count: 2)
          assert page.has_css?(".govuk-input[value='']", count: 2)
        end
      end

      should "redirect to tagging tab when Cancel link is clicked" do
        click_link("Cancel")
        assert_current_path tagging_edition_path(@draft_edition.id)
      end

      should "display an error when the form is submitted if a value entered is not a valid path" do
        Services.publishing_api.stubs(:lookup_content_ids).returns({ "/company-tax-returns" => "830e403b-7d81-45f1-8862-81dcd55b4ec7", "/prepare-file-annual-accounts-for-limited-company" => "5cb58486-0b00-4da8-8076-382e474b4f03" })

        within all(".js-add-another__fieldset")[0] do
          fill_in "URL or path", with: "/invalid-path"
        end

        click_button("Save")

        assert_current_path update_related_content_edition_path(@draft_edition.id)
        assert page.has_text?("/invalid-path is not a known URL on GOV.UK, check URL or path is correctly entered.")
      end

      should "save the added 'Related content' tags when the form is submitted" do
        within all(".js-add-another__fieldset")[0] do
          fill_in "URL or path", with: "/company-tax-returns"
        end

        click_button("Save")

        assert_requested :patch,
                         "#{Plek.find('publishing-api')}/v2/links/#{@draft_edition.content_id}",
                         body: { "links": { "organisations": [],
                                            "mainstream_browse_pages": [],
                                            "ordered_related_items": %w[830e403b-7d81-45f1-8862-81dcd55b4ec7],
                                            "parent": [] },
                                 "previous_version": 0 }
        assert_current_path tagging_edition_path(@draft_edition.id)
        assert page.has_text?("Related content updated")
      end
    end

    context "Editing tags for a related content page" do
      setup do
        stub_linkables_with_data
        visit tagging_related_content_page_edition_path(@draft_edition)
      end

      should "render a pre-populated Add Another form" do
        within :css, ".gem-c-add-another" do
          assert page.has_css?("legend", text: "Related content 1")
          assert page.has_css?("label", text: "URL or path")
          assert page.has_css?(".gem-c-hint", text: "For example, /pay-vat")
          assert page.has_css?(".govuk-input", count: 5)
          assert page.has_css?("input[value='/company-tax-returns']")
          assert page.has_css?("input[value='/prepare-file-annual-accounts-for-limited-company']")
          assert page.has_css?("input[value='/corporation-tax']")
          assert page.has_css?("input[value='/tax-help']")
        end
      end

      should "redirect to tagging tab when Cancel link is clicked" do
        click_link("Cancel")
        assert_current_path tagging_edition_path(@draft_edition.id)
      end

      should "save deleted 'Related content' tags when the form is submitted" do
        within all(".js-add-another__fieldset")[1] do
          check("Delete")
        end
        within all(".js-add-another__fieldset")[3] do
          check("Delete")
        end

        click_button("Save")

        assert_requested :patch,
                         "#{Plek.find('publishing-api')}/v2/links/#{@draft_edition.content_id}",
                         body: { "links": { "organisations": %w[9a9111aa-1db8-4025-8dd2-e08ec3175e72],
                                            "mainstream_browse_pages": %w[CONTENT-ID-CAPITAL CONTENT-ID-RTI CONTENT-ID-VAT],
                                            "ordered_related_items": %w[830e403b-7d81-45f1-8862-81dcd55b4ec7 853feaf2-152c-4aa5-8edb-ba84a88860bf],
                                            "parent": %w[CONTENT-ID-CAPITAL] },
                                 "previous_version": 1 }
        assert_current_path tagging_edition_path(@draft_edition.id)
        assert page.has_text?("Related content updated")
      end

      should "save edited 'Related content' tags when the form is submitted" do
        within all(".js-add-another__fieldset")[0] do
          fill_in "URL or path", with: "/tax-help"
        end
        within all(".js-add-another__fieldset")[1] do
          fill_in "URL or path", with: "/corporation-tax"
        end
        within all(".js-add-another__fieldset")[2] do
          fill_in "URL or path", with: "/company-tax-returns"
        end
        within all(".js-add-another__fieldset")[3] do
          fill_in "URL or path", with: "/prepare-file-annual-accounts-for-limited-company"
        end

        click_button("Save")

        assert_requested :patch,
                         "#{Plek.find('publishing-api')}/v2/links/#{@draft_edition.content_id}",
                         body: { "links": { "organisations": %w[9a9111aa-1db8-4025-8dd2-e08ec3175e72],
                                            "mainstream_browse_pages": %w[CONTENT-ID-CAPITAL CONTENT-ID-RTI CONTENT-ID-VAT],
                                            "ordered_related_items": %w[91fef6f6-3a59-42ab-a14d-42c4e5eee1a1 853feaf2-152c-4aa5-8edb-ba84a88860bf 830e403b-7d81-45f1-8862-81dcd55b4ec7 5cb58486-0b00-4da8-8076-382e474b4f03],
                                            "parent": %w[CONTENT-ID-CAPITAL] },
                                 "previous_version": 1 }
        assert_current_path tagging_edition_path(@draft_edition.id)
        assert page.has_text?("Related content updated")
      end
    end

    context "Reordering tags for a related content page" do
      setup do
        stub_linkables_with_data
        visit tagging_reorder_related_content_page_edition_path(@draft_edition)
      end

      should "submit original tags when the form is submitted with no changes" do
        click_button("Update order")

        assert_requested :patch,
                         "#{Plek.find('publishing-api')}/v2/links/#{@draft_edition.content_id}",
                         body: { "links": { "organisations": %w[9a9111aa-1db8-4025-8dd2-e08ec3175e72],
                                            "mainstream_browse_pages": %w[CONTENT-ID-CAPITAL CONTENT-ID-RTI CONTENT-ID-VAT],
                                            "ordered_related_items": %w[830e403b-7d81-45f1-8862-81dcd55b4ec7 5cb58486-0b00-4da8-8076-382e474b4f03 853feaf2-152c-4aa5-8edb-ba84a88860bf 91fef6f6-3a59-42ab-a14d-42c4e5eee1a1],
                                            "parent": %w[CONTENT-ID-CAPITAL] },
                                 "previous_version": 1 }
        assert_current_path tagging_edition_path(@draft_edition.id)
        assert page.has_text?("Related content order updated")
      end

      should "submit reordered tags when the form is submitted with changes" do
        within all(".gem-c-reorderable-list__item")[0] do
          fill_in "Position", with: "2"
        end
        within all(".gem-c-reorderable-list__item")[1] do
          fill_in "Position", with: "1"
        end
        within all(".gem-c-reorderable-list__item")[2] do
          fill_in "Position", with: "4"
        end
        within all(".gem-c-reorderable-list__item")[3] do
          fill_in "Position", with: "3"
        end

        click_button("Update order")

        assert_requested :patch,
                         "#{Plek.find('publishing-api')}/v2/links/#{@draft_edition.content_id}",
                         body: { "links": { "organisations": %w[9a9111aa-1db8-4025-8dd2-e08ec3175e72],
                                            "mainstream_browse_pages": %w[CONTENT-ID-CAPITAL CONTENT-ID-RTI CONTENT-ID-VAT],
                                            "ordered_related_items": %w[5cb58486-0b00-4da8-8076-382e474b4f03 830e403b-7d81-45f1-8862-81dcd55b4ec7 91fef6f6-3a59-42ab-a14d-42c4e5eee1a1 853feaf2-152c-4aa5-8edb-ba84a88860bf],
                                            "parent": %w[CONTENT-ID-CAPITAL] },
                                 "previous_version": 1 }
        assert_current_path tagging_edition_path(@draft_edition.id)
        assert page.has_text?("Related content order updated")
      end
    end
  end
end
