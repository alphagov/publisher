require "integration_test_helper"

class EditionEditTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    @govuk_requester = FactoryBot.create(:user, :govuk_editor, name: "Stub requester")
    login_as(@govuk_editor)
    @test_strategy = Flipflop::FeatureSet.current.test!
    @test_strategy.switch!(:design_system_edit_phase_3a, true)
    stub_holidays_used_by_fact_check
    stub_linkables
    stub_events_for_all_content_ids
    stub_users_from_signon_api
    UpdateWorker.stubs(:perform_async)
  end

  context "edit page" do
    should "show all the tabs when user has required permission and edition is published" do
      visit_published_edition

      assert page.has_text?("Edit")
      assert page.has_text?("Tagging")
      assert page.has_text?("Metadata")
      assert page.has_text?("History and notes")
      assert page.has_text?("Admin")
      assert page.has_text?("Related external links")
      assert page.has_text?("Unpublish")
    end

    should "show document summary and title" do
      visit_published_edition

      assert page.has_title?("Edit page title")

      row = find_all(".govuk-summary-list__row")
      assert row[0].has_content?("Assigned to")
      assert row[1].has_text?("Content type")
      assert row[1].has_text?("Answer")
      assert row[2].has_text?("Edition")
      assert row[2].has_text?("1")
      assert row[2].has_text?("Published")
    end

    should "show scheduled date and time when an edition is scheduled for publishing" do
      travel_to Time.zone.local(2025, 3, 4, 17, 16, 15)
      scheduled_for_publishing_edition = FactoryBot.create(
        :edition,
        :scheduled_for_publishing,
        publish_at: Time.zone.now,
      )

      visit edition_path(scheduled_for_publishing_edition)

      row = find_all(".govuk-summary-list__row")
      assert_equal 4, row.count, "Expected four rows in the summary"
      assert row[2].has_text?(/Scheduled for publishing$/)
      assert row[3].has_text?("Scheduled")
      assert row[3].has_text?("5:16pm, 4 March 2025")
    end

    %i[draft amends_needed fact_check_received ready archived published].each do |state|
      should "not show a scheduled row when an edition is in the '#{state}' state" do
        edition = FactoryBot.create(:edition, state:)

        visit edition_path(edition)

        row = find_all(".govuk-summary-list__row")
        assert_equal 3, row.count, "Expected three rows in the summary"
        assert page.has_no_content?("Scheduled")
      end
    end

    should "not show a scheduled row when an edition is in the 'in_review' state" do
      edition = FactoryBot.create(:edition, state: "in_review", review_requested_at: 1.hour.ago)
      edition.actions.create!(
        request_type: Action::REQUEST_AMENDMENTS,
        requester_id: @govuk_requester.id,
      )

      visit edition_path(edition)

      row = find_all(".govuk-summary-list__row")
      assert_equal 4, row.count, "Expected four rows in the summary"
      assert page.has_no_content?("Scheduled")
    end

    should "indicate when an edition does not have an assignee" do
      visit_published_edition

      within all(".govuk-summary-list__row")[0] do
        assert_selector(".govuk-summary-list__key", text: "Assigned to")
        assert_selector(".govuk-summary-list__value", text: "None")
      end
    end

    should "show the person assigned to an edition" do
      visit_draft_edition

      within all(".govuk-summary-list__row")[0] do
        assert_selector(".govuk-summary-list__key", text: "Assigned to")
        assert_selector(".govuk-summary-list__value", text: @draft_edition.assignee)
      end
    end

    should "not show the 2i reviewer row in the summary if the edition state is not 'in_review'" do
      %i[draft amends_needed fact_check fact_check_received ready scheduled_for_publishing published archived].each do |state|
        send "visit_#{state}_edition"

        within :css, ".govuk-summary-list" do
          assert_no_selector(".govuk-summary-list__key", text: "2i reviewer")
        end
      end
    end

    should "show the 2i reviewer row in the summary correctly if the edition state is 'in_review' and a reviewer is not assigned" do
      visit_in_review_edition

      within all(".govuk-summary-list__row")[3] do
        assert_selector(".govuk-summary-list__key", text: "2i reviewer")
        assert_selector(".govuk-summary-list__value", text: "Not yet claimed")
      end
    end

    should "show the 2i reviewer row in the summary correctly if the edition state is 'in_review' and a reviewer is assigned" do
      edition = FactoryBot.create(:answer_edition, state: "in_review", title: "An edition with a reviewer assigned", review_requested_at: 1.hour.ago, reviewer: @govuk_editor.name)
      edition.actions.create!(
        request_type: Action::REQUEST_AMENDMENTS,
        requester_id: @govuk_requester.id,
      )

      visit edition_path(edition)

      within all(".govuk-summary-list__row")[3] do
        assert_selector(".govuk-summary-list__key", text: "2i reviewer")
        assert_selector(".govuk-summary-list__value", text: "Stub User")
      end
    end

    should "display the important note if an important note exists" do
      note_text = "This is really really urgent!"
      create_draft_edition
      create_important_note_for_edition(@draft_edition, note_text)
      visit edition_path(@draft_edition)

      within :css, ".govuk-notification-banner" do
        assert page.has_text?("Important")
        assert page.has_text?(note_text)
        assert page.has_text?(@govuk_editor.name)
        assert page.has_text?(Time.zone.today.to_date.to_fs(:govuk_date))
      end
    end

    should "display only the most recent important note at the top" do
      first_note = "This is really really urgent!"
      second_note = "This should display only!"
      create_draft_edition
      create_important_note_for_edition(@draft_edition, first_note)
      create_important_note_for_edition(@draft_edition, second_note)

      visit edition_path(@draft_edition)

      assert page.has_text?("Important")
      assert page.has_text?(second_note)
      assert page.has_no_text?(first_note)
    end
  end

  context "edit assignee page" do
    should "only show editors as available for assignment" do
      edition = FactoryBot.create(:edition, state: "draft")
      non_editor_user = FactoryBot.create(:user, name: "Non Editor User")
      visit edit_assignee_edition_path(edition)

      assert_selector "label", text: @govuk_editor.name
      assert_no_selector "label", text: non_editor_user.name
    end
  end

  context "tagging tab" do
    context "No tagging is set" do
      setup do
        visit_draft_edition
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
          visit_draft_edition
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
        visit_draft_edition
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
          visit_draft_edition
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
      setup do
        stub_linkables_with_single_related_item
        visit_draft_edition
        click_link("Tagging")
      end

      should "not show 'Reorder' link on 'Related content' summary card when only one related content item is present" do
        within all(".gem-c-summary-card")[3] do
          assert page.has_link?("Edit")
          assert page.has_no_link?("Reorder")
        end
      end
    end
  end

  context "Breadcrumb page" do
    setup do
      visit_draft_edition
      click_link("Tagging")
    end

    context "Setting a breadcrumb" do
      setup do
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
        visit_draft_edition
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
  end

  context "Removing a breadcrumb" do
    setup do
      stub_linkables_with_data
      visit_draft_edition
      click_link("Tagging")
      within all(".gem-c-summary-card")[0] do
        click_link("Remove")
      end
    end

    should "show the remove breadcrumb page " do
      assert page.has_text?(@draft_edition.title)
      assert page.has_text?("Are you sure you want to remove the breadcumb?")
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

  context "Mainstream browse pages page" do
    setup do
      visit_draft_edition
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
        visit_draft_edition
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

  context "Tag related content page" do
    setup do
      create_draft_edition
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

  context "Tag organisations page" do
    setup do
      create_draft_edition
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

  context "metadata tab" do
    context "when state is 'draft' and user has govuk editor permissions" do
      setup do
        visit_draft_edition
        click_link("Metadata")
      end

      should "show 'Metadata' header and an update button" do
        within :css, ".gem-c-heading h2" do
          assert page.has_text?("Metadata")
        end
        assert page.has_button?("Update")
      end

      should "show slug input box prefilled" do
        assert page.has_text?("Slug")
        assert page.has_text?("If you change the slug of a published page, the old slug will automatically redirect to the new one.")
        assert page.has_field?("artefact[slug]", with: /slug/)
      end

      should "update and show success message" do
        fill_in "artefact[slug]", with: "changed-slug"
        choose("Welsh")
        click_button("Update")

        assert find(".gem-c-radio input[value='cy']").checked?
        assert page.has_text?("Metadata has successfully updated")
        assert page.has_field?("artefact[slug]", with: "changed-slug")
      end
    end

    context "when user has welsh editor permissions" do
      should "show read-only values and no 'Update' button for welsh edition" do
        @welsh_edition = FactoryBot.create(
          :edition,
          title: "Edit page title",
          panopticon_id: FactoryBot.create(
            :artefact,
            slug: "welsh-language-edition-test",
            language: "cy",
          ).id,
          state: "ready",
          slug: "welsh-language-edition-test",
        )

        login_as_welsh_editor
        visit edition_path(@welsh_edition)
        click_link("Metadata")

        assert @user.has_editor_permissions?(@welsh_edition)
        assert page.has_no_field?("artefact[slug]")
        assert page.has_no_field?("artefact[language]")
        assert page.has_text?("Slug")
        assert page.has_text?(/welsh-language-edition-test/)
        assert page.has_text?("Language")
        assert page.has_text?(/Welsh/)
        assert page.has_no_button?("Update")
      end

      should "show read-only values and no 'Update' button for a non-welsh edition" do
        visit_draft_edition
        login_as_welsh_editor
        click_link("Metadata")

        assert_not @user.has_editor_permissions?(@draft_edition)
        assert page.has_no_field?("artefact[slug]")
        assert page.has_no_field?("artefact[language]")
        assert page.has_text?("Slug")
        assert page.has_text?("Language")
        assert page.has_no_button?("Update")
      end
    end

    context "when user has no permissions" do
      should "show read-only values and no 'Update' button" do
        user = FactoryBot.create(:user, name: "Stub User")
        login_as(user)
        visit_draft_edition
        click_link("Metadata")

        assert_not user.has_editor_permissions?(@draft_edition)
        assert page.has_no_button?("Update")
      end
    end

    context "when state is not 'draft'" do
      setup do
        visit_published_edition
        click_link("Metadata")
      end

      should "show read-only values and no 'Update' button" do
        assert page.has_no_field?("artefact[slug]")
        assert page.has_no_field?("artefact[language]")
        assert page.has_text?("Slug")
        assert page.has_text?(/can-i-get-a-driving-licence/)
        assert page.has_text?("Language")
        assert page.has_text?(/English/)
        assert page.has_no_button?("Update")
      end
    end
  end

  context "History and notes tab" do
    setup do
      visit_draft_edition
      click_link("History and notes")
    end

    should "show a heading" do
      assert page.has_css?("h2", text: "History and notes")
    end

    should "show inset text" do
      within :css, ".gem-c-inset-text" do
        assert page.has_text?("Send fact check responses to #{@draft_edition.fact_check_email_address} and include [#{@draft_edition.id}] in the subject line.")
      end
    end

    should "show an 'Add edition note' button" do
      assert page.has_link?("Add edition note")
    end

    should "navigate to the 'Add edition note' page when the button is clicked" do
      click_link("Add edition note")

      assert_current_path history_add_edition_note_edition_path(@draft_edition.id)
    end

    should "display the accordion section headers" do
      assert page.has_css?(".govuk-accordion__section-header h2", text: "Edition 1")
    end

    should "show an 'Update important note' button" do
      assert page.has_link?("Update important note")
    end

    should "navigate to the 'Update important note' page when the button is clicked" do
      click_link("Update important note")

      assert_current_path history_update_important_note_edition_path(@draft_edition.id)
    end

    context "show a Preview or a view on GOV.UK link" do
      should "show a Preview button when the edition is draft" do
        visit_draft_edition
        click_link("History and notes")

        assert page.has_link?("Preview (opens in new tab)")
      end

      should "show a Preview button when the edition is in review" do
        visit_in_review_edition
        click_link("History and notes")

        assert page.has_link?("Preview (opens in new tab)")
      end

      should "show a Preview button when the edition is out for fact check" do
        visit_fact_check_edition
        click_link("History and notes")

        assert page.has_link?("Preview (opens in new tab)")
      end

      should "show a Preview button when the edition is ready" do
        visit_ready_edition
        click_link("History and notes")

        assert page.has_link?("Preview (opens in new tab)")
      end

      should "show a Preview button when the edition is scheduled for publishing" do
        visit_scheduled_for_publishing_edition
        click_link("History and notes")

        assert page.has_link?("Preview (opens in new tab)")
      end

      should "show a View on GOV.UK button when the edition is published" do
        visit_published_edition
        click_link("History and notes")

        assert page.has_link?("View on GOV.UK (opens in new tab)")
      end

      should "show a View on GOV.UK button when the edition is archived" do
        visit_archived_edition
        click_link("History and notes")

        assert page.has_link?("View on GOV.UK (opens in new tab)")
      end

      should "still show the conditional preview/view link when the user does not have editor permissions" do
        @stub_user = FactoryBot.create(:user, name: "Stub user")
        login_as(@stub_user)
        visit_draft_edition
        click_link("History and notes")

        assert page.has_link?("Preview (opens in new tab)")
      end
    end

    context "when the user has no permissions" do
      should "hide the note action buttons from the user" do
        user = FactoryBot.create(:user, name: "Stub User")
        login_as(user)
        visit_draft_edition
        click_link("History and notes")

        assert_not user.has_editor_permissions?(@draft_edition)
        assert_not page.has_content?("Add edition note")
        assert_not page.has_content?("Update important note")
      end
    end

    context "when the user has welsh editor permissions" do
      setup do
        @user = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
        @user_welsh = FactoryBot.create(:user, :welsh_editor, name: "Stub User")
        login_as(@user)
      end

      should "hide the note action buttons from the user on a non welsh document" do
        visit_draft_edition
        login_as(@user_welsh)
        click_link("History and notes")

        assert_not @user_welsh.has_editor_permissions?(@draft_edition)
        assert_not page.has_content?("Add edition note")
        assert_not page.has_content?("Update important note")
      end

      should "show the note action buttons for the user on a welsh document" do
        edition = @user.create_edition(:answer, panopticon_id: FactoryBot.create(:artefact, language: "cy").id, title: "My Title", slug: "my-title")
        edition.state = "fact_check"
        edition.save!

        login_as(@user_welsh)

        visit edition_path(edition)
        click_link("History and notes")

        assert @user_welsh.has_editor_permissions?(edition)
        assert page.has_content?("Add edition note")
        assert page.has_content?("Update important note")
      end
    end

    context "Edition displays the correct data for actions" do
      setup do
        @edition = FactoryBot.create(:edition, created_at: "2024-01-23")
      end

      should "display 'Assign' action" do
        user = FactoryBot.create(:user, name: "Steve Ogrizovic")
        @edition.actions.create! request_type: Action::ASSIGN, requester_id: user.id, created_at: "2024-02-24 15:41:00", comment: "Assigned to me"

        visit edition_path(@edition)
        click_link("History and notes")

        within :css, ".history__action--assign__heading" do
          assert page.has_css?("time", text: "3:41pm, 24 February 2024")
          assert page.has_text?("Assign by Steve Ogrizovic")
        end

        within :css, ".history__action--assign__content" do
          assert page.has_text?("Assigned to me")
        end
      end

      should "display 'Note' action" do
        user = FactoryBot.create(:user, name: "David Phillips")
        @edition.actions.create! request_type: Action::NOTE, requester_id: user.id, created_at: "2024-03-01 10:30:00", comment: "This is a note"

        visit edition_path(@edition)
        click_link("History and notes")

        within :css, ".history__action--note__heading" do
          assert page.has_css?("time", text: "10:30am, 1 March 2024")
          assert page.has_text?("Note by David Phillips")
        end

        within :css, ".history__action--note__content" do
          assert page.has_text?("This is a note")
        end
      end

      should "display 'Request review' action" do
        user = FactoryBot.create(:user, name: "Greg Downs")
        @edition.actions.create! request_type: Action::REQUEST_REVIEW, requester_id: user.id, created_at: "2024-04-02 17:23:00", comment: "Requesting review"

        visit edition_path(@edition)
        click_link("History and notes")

        within :css, ".history__action--request_review__heading" do
          assert page.has_css?("time", text: "5:23pm, 2 April 2024")
          assert page.has_text?("Request review by Greg Downs")
        end

        within :css, ".history__action--request_review__content" do
          assert page.has_text?("Requesting review")
        end
      end

      should "display 'Send fact check' action" do
        user = FactoryBot.create(:user, name: "Lloyd McGrath")
        @edition.actions.create! request_type: Action::SEND_FACT_CHECK, requester_id: user.id, created_at: "2024-05-16 18:12:00", comment: "Fact check requested"

        visit edition_path(@edition)
        click_link("History and notes")

        within :css, ".history__action--send_fact_check__heading" do
          assert page.has_css?("time", text: "6:12pm, 16 May 2024")
          assert page.has_text?("Send fact check by Lloyd McGrath")
        end

        within :css, ".history__action--send_fact_check__content" do
          assert page.has_text?("Fact check requested")
        end
      end

      should "display 'Receive fact check' action" do
        @edition.actions.create! request_type: Action::RECEIVE_FACT_CHECK, created_at: "2024-06-06 8:32:00", comment: "We’re happy for you to publish. -----Original Message----- Reply and confirm the content is correct.", comment_sanitized: true

        visit edition_path(@edition)
        click_link("History and notes")

        within :css, ".history__action--receive_fact_check__heading" do
          assert page.has_css?("time", text: "8:32am, 6 June 2024")
          assert page.has_text?("Receive fact check by GOV.UK Bot")
        end

        within :css, ".history__action--receive_fact_check__content" do
          assert page.has_text?("We’re happy for you to publish.")
          assert page.has_css?("div.js-earlier", text: "Reply and confirm the content is correct.")
          assert page.has_text?("We found some potentially harmful content in this email which has been automatically removed. Please check the content of the message in case any text has been deleted as well.")
        end
      end

      should "display 'Request amendments' action" do
        user = FactoryBot.create(:user, name: "Brian Kilcline")
        @edition.actions.create! request_type: Action::REQUEST_AMENDMENTS, requester_id: user.id, created_at: "2024-06-27 10:56:00", comment: "Requesting amendments"

        visit edition_path(@edition)
        click_link("History and notes")

        within :css, ".history__action--request_amendments__heading" do
          assert page.has_css?("time", text: "10:56am, 27 June 2024")
          assert page.has_text?("Request amendments by Brian Kilcline")
        end

        within :css, ".history__action--request_amendments__content" do
          assert page.has_text?("Requesting amendments")
        end
      end

      should "display 'Approve review' action" do
        user = FactoryBot.create(:user, name: "Trevor Peake")
        @edition.actions.create! request_type: Action::APPROVE_REVIEW, requester_id: user.id, created_at: "2024-07-05 19:31:00", comment: "Review approved"

        visit edition_path(@edition)
        click_link("History and notes")

        within :css, ".history__action--approve_review__heading" do
          assert page.has_css?("time", text: "7:31pm, 5 July 2024")
          assert page.has_text?("Approve review by Trevor Peake")
        end

        within :css, ".history__action--approve_review__content" do
          assert page.has_text?("Review approved")
        end
      end

      should "display 'Content block update' action on Published and In Progress Editions" do
        user = FactoryBot.create(:user, :govuk_editor, name: "Dave Bennett")
        event = create_content_update_event(updated_by_user_uid: user["uid"])

        stub_events_for_all_content_ids(events: [event])
        stub_users_from_signon_api([user.uid], [user])

        visit edition_path(@edition)
        click_link("History and notes")

        within :css, ".history__action--content_block_update__heading" do
          assert page.has_css?("time", text: "11:26am, 7 August 2024")
          assert page.has_text?("Content block updated by Dave Bennett")
        end

        within :css, ".history__action--content_block_update__content" do
          assert page.has_text?("Email address updated")
          assert page.has_link?("View in Content Block Manager")
        end

        published_edition = FactoryBot.create(
          :edition,
          state: "published",
          created_at: Time.zone.parse(event["created_at"]).to_date - 1.day,
        )

        published_edition.actions.create!(
          request_type: Action::PUBLISH,
          requester: user,
        )

        visit edition_path(published_edition)
        click_link("History and notes")

        within :css, ".history__action--content_block_update__heading" do
          assert page.has_css?("time", text: "11:26am, 7 August 2024")
          assert page.has_text?("Content block updated by Dave Bennett")
        end

        within :css, ".history__action--content_block_update__content" do
          assert page.has_text?("Email address updated")
          assert page.has_link?("View in Content Block Manager")
        end
      end

      should "does not display 'Content block update' action on Editions archived before the update" do
        user = FactoryBot.create(:user, :govuk_editor, name: "Dave Bennett")

        archived_edition = FactoryBot.create(:edition, state: "archived")
        archived_edition.artefact.update!(state: "archived")

        event = create_content_update_event(updated_by_user_uid: user["uid"])

        stub_events_for_all_content_ids(events: [event])
        stub_users_from_signon_api([user.uid], [user])

        visit edition_path(archived_edition)
        click_link("History and notes")

        assert page.has_no_css?(".history__action--content_block_update__heading")
        assert page.has_no_css?(".history__action--content_block_update__content")
      end
    end

    context "when there are previous editions" do
      should "display a link to compare editions" do
        edition_one = FactoryBot.create(:answer_edition, :published)
        edition_two = FactoryBot.create(
          :answer_edition,
          :published,
          panopticon_id: edition_one.panopticon_id,
          title: "Second edition title",
        )

        visit history_edition_path(edition_two)
        page.find("a", text: "Compare with Edition 1").click

        page.find("h1", text: "Compare edition 1 and 2")
        assert page.has_css?("h1", text: "Compare edition 1 and 2")
        assert page.has_content?(edition_two.title)
      end
    end

    context "when there are not previous editions" do
      should "not display a link to compare editions" do
        edition_one = FactoryBot.create(:answer_edition, :published)

        visit history_edition_path(edition_one)
        page.find("h2", text: "History and notes")

        assert page.has_no_css?("a", text: "Compare with Edition")
      end
    end
  end

  context "Add edition note page" do
    setup do
      visit_draft_edition
      click_link("History and notes")
      click_link("Add edition note")
    end

    should "render the 'Add edition note' page" do
      within :css, ".gem-c-heading" do
        assert page.has_css?("h1", text: "Add edition note")
        assert page.has_css?(".gem-c-heading__context", text: @draft_edition.title)
      end

      assert page.has_text?("Explain what changes you did or did not make and why. Include a link to the relevant Zendesk ticket and Jira card. You can also add an edition note when you send the edition for 2i review. Read guidance on writing good change notes (opens in new tab).")

      within :css, ".gem-c-textarea" do
        assert page.has_css?("label", text: "Edition note")
        assert page.has_css?("textarea")
      end

      assert page.has_button?("Save")
      assert page.has_link?("Cancel")
    end
  end

  context "Update important note page" do
    should "render the 'Update important note' page" do
      create_draft_edition
      visit history_update_important_note_edition_path(@draft_edition)

      within :css, ".gem-c-heading" do
        assert page.has_css?("h1", text: "Update important note")
        assert page.has_css?(".gem-c-heading__context", text: @draft_edition.title)
      end

      assert page.has_text?("Add important notes that anyone who works on this edition needs to see, eg “(Doesn’t) need fact check, don’t publish.”.")
      assert page.has_text?("Each edition can have only one important note at a time.")
      assert page.has_text?("To delete the important note, clear any comments and select ‘Save’.")

      within :css, ".gem-c-textarea" do
        assert page.has_css?("label", text: "Important note")
        assert page.has_css?("textarea")
      end

      assert page.has_button?("Save")
      assert page.has_link?("Cancel")
    end

    should "pre-populate with the existing note" do
      note_text = "This is really really urgent!"
      create_draft_edition
      create_important_note_for_edition(@draft_edition, note_text)
      visit history_update_important_note_edition_path(@draft_edition)

      assert page.has_field?("Important note", with: note_text)
    end

    should "not show important notes in edition history" do
      note_text = "This is really really urgent!"
      note_text_2 = "Another note"
      note_text_3 = "Yet another note"

      create_draft_edition
      create_important_note_for_edition(@draft_edition, note_text)
      create_important_note_for_edition(@draft_edition, note_text_2)
      create_important_note_for_edition(@draft_edition, note_text_3)

      visit edition_path(@draft_edition)
      click_link("History and notes")

      within :css, ".history__actions" do
        assert page.has_no_text?("Important note updated by #{@govuk_editor.name}")
        assert page.has_no_text?("This is really really urgent!")
        assert page.has_no_text?("Another note")
        assert page.has_no_text?("Yet another note")
      end
    end

    should "not be carried forward to new editions" do
      note_text = "This important note should not appear on a new edition."
      create_published_edition
      create_important_note_for_edition(@published_edition, note_text)
      visit edition_path(@published_edition)

      assert page.has_content? note_text

      click_on "Create new edition"
      assert page.has_no_text?("Important note")
    end
  end

  context "unpublish tab" do
    context "user does not have required permissions" do
      setup do
        login_as(FactoryBot.create(:user, name: "Stub User"))
        visit_draft_edition
      end

      should "not show unpublish tab when user is not govuk editor" do
        assert page.has_no_text?("Unpublish")
      end
    end

    context "user has required permissions" do
      setup do
        visit_draft_edition
      end

      context "when state is 'published'" do
        setup do
          visit_published_edition
          click_link("Unpublish")
        end

        should "show 'Unpublish' header and 'Continue' button" do
          within :css, ".gem-c-heading h2" do
            assert page.has_text?("Unpublish")
          end
          assert page.has_button?("Continue")
        end

        should "show 'cannot be undone' banner" do
          assert page.has_text?("If you unpublish a page from GOV.UK it cannot be undone.")
        end

        should "show 'Redirect to URL' text, input box and example text" do
          assert page.has_text?("Redirect to URL")
          assert page.has_text?("For example: https://www.gov.uk/redirect-to-replacement-page")
          assert page.has_css?(".govuk-input", count: 1)
        end

        should "navigate to 'confirm-unpublish' page when 'Continue' button is clicked" do
          click_button("Continue")
          assert_equal(page.current_path, "/editions/#{@published_edition.id}/unpublish/confirm-unpublish")
        end
      end

      context "when state is not 'published'" do
        setup do
          edition = FactoryBot.create(:edition, state: "draft")
          visit edition_path(edition)
        end

        should "not show unpublish tab" do
          assert page.has_no_text?("Unpublish")
        end
      end
    end
  end

  context "admin tab" do
    context "user does not have required permissions" do
      setup do
        login_as(FactoryBot.create(:user, name: "Stub User"))
        visit_draft_edition
      end

      should "not show when user is not govuk editor or welsh editor" do
        assert page.has_no_text?("Admin")
      end

      should "not show when user is welsh editor and edition is not welsh" do
        login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
        visit_draft_edition

        assert page.has_no_text?("Admin")
      end
    end

    context "user has required permissions" do
      %i[draft amends_needed in_review fact_check_received ready archived scheduled_for_publishing].each do |state|
        context "when state is '#{state}'" do
          setup do
            send "visit_#{state}_edition"
            click_link("Admin")
          end

          should "not show the 'Update content type' form" do
            assert page.has_no_text?("Update content type")
          end
        end
      end

      %i[published archived scheduled_for_publishing].each do |state|
        context "when state is '#{state}'" do
          setup do
            send "visit_#{state}_edition"
            click_link("Admin")
          end

          should "show 'Admin' header and not show 'Skip fact check' button" do
            within :css, ".gem-c-heading h2" do
              assert page.has_text?("Admin")
            end
            assert page.has_no_button?("Skip fact check")
          end

          should "not show link to delete edition" do
            assert page.has_no_link?("Delete edition")
          end
        end
      end

      %i[draft amends_needed in_review fact_check_received ready].each do |state|
        context "when state is '#{state}'" do
          setup do
            send "visit_#{state}_edition"
            click_link("Admin")
          end

          should "show 'Admin' header and not show 'Skip fact check' button" do
            within :css, ".gem-c-heading h2" do
              assert page.has_text?("Admin")
            end
            assert page.has_no_button?("Skip fact check")
          end

          should "show link to delete edition" do
            assert page.has_link?("Delete edition")
          end
        end
      end

      context "when state is 'fact_check'" do
        setup do
          visit_fact_check_edition
          click_link("Admin")
        end

        should "show 'Admin' tab when user is welsh editor and edition is welsh edition" do
          login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
          welsh_edition = FactoryBot.create(:edition, :fact_check, :welsh)
          visit edition_path(welsh_edition)

          assert page.has_text?("Admin")
        end

        should "show 'Admin' header and an 'Skip fact check' button" do
          within :css, ".gem-c-heading h2" do
            assert page.has_text?("Admin")
          end
          assert page.has_button?("Skip fact check")
        end

        should "show link to delete edition" do
          assert page.has_link?("Delete edition")
        end

        should "show success message when fact check skipped successfully" do
          click_button("Skip fact check")
          @fact_check_edition.reload

          assert_equal "ready", @fact_check_edition.state
          assert page.has_text?("The fact check has been skipped for this publication.")
        end

        should "show error message when skip fact check gives an error" do
          User.any_instance.stubs(:progress).returns(false)

          click_button("Skip fact check")
          @fact_check_edition.reload

          assert_equal "fact_check", @fact_check_edition.state
          assert page.has_text?("Could not skip fact check for this publication.")
        end
      end

      context "when state is 'published'" do
        context "edition is not the latest version of a publication" do
          setup do
            visit_old_edition_of_published_edition
            click_link("Admin")
          end

          should "not show the 'Update content type' form" do
            assert page.has_no_text?("Update content type")
          end
        end

        context "content type is not retired, edition is the latest version of a publication" do
          setup do
            visit_published_edition
            click_link("Admin")
          end

          should "show the 'Update content type' form" do
            assert page.has_text?("Update content type")
          end

          should "show radio buttons for all content types excluding current one (answer)" do
            assert page.has_no_selector?(".gem-c-radio input[value='answer']")
            assert page.has_selector?(".gem-c-radio input[value='completed_transaction']")
            assert page.has_selector?(".gem-c-radio input[value='guide']")
            assert page.has_selector?(".gem-c-radio input[value='help_page']")
            assert page.has_selector?(".gem-c-radio input[value='place']")
            assert page.has_selector?(".gem-c-radio input[value='simple_smart_answer']")
            assert page.has_selector?(".gem-c-radio input[value='transaction']")
          end

          should "show common explanatory text for all content types and not show explanatory text specific to Guides" do
            assert page.has_text?("No content will be lost, but content in some fields might not make it into the new edition. If it can't be copied to a new content type it will still be available in the previous edition. Content in multiple fields might be combined into a single field.")
            assert page.has_no_text?("All parts of Guide Editions will be copied across. If the format you are converting to doesn't have parts, the content of all the parts will be copied into the body, with the part title displayed as a top-level sub-heading.")
          end
        end
      end

      context "confirm delete" do
        setup do
          visit_draft_edition
          click_link("Admin")
          click_link("Delete edition #{@draft_edition.version_number}")
        end

        should "show the delete edition confirmation page" do
          assert page.has_text?(@draft_edition.title)
          assert page.has_text?("Delete edition")
          assert page.has_text?("If you delete this edition it cannot be undone.")
          assert page.has_text?("Are you sure you want to delete this edition?")
          assert page.has_link?("Cancel")
          assert page.has_button?("Delete edition")
        end

        should "navigate to admin tab when 'Cancel' is clicked" do
          click_link("Cancel")

          assert_current_path admin_edition_path(@draft_edition.id)
        end

        should "navigate to root path when 'Delete edition' is clicked" do
          click_button("Delete edition")

          assert_current_path root_path
        end

        should "show success message when edition is successfully deleted" do
          click_button("Delete edition")

          assert_equal 0, Edition.where(id: @draft_edition.id).count
          assert page.has_text?("Edition deleted")
        end
      end
    end
  end

  context "edit tab" do
    context "draft edition of a new publication" do
      setup do
        visit_draft_edition
      end

      should "show 'Metadata' header and an update button" do
        within :css, ".gem-c-heading h2" do
          assert page.has_text?("Edit")
        end
        assert page.has_button?("Save")
      end

      should "show 'Send to 2i' link" do
        assert page.has_link?("Send to 2i")
      end

      should "show Preview link" do
        assert page.has_link?("Preview (opens in new tab)")
      end

      should "show Title input box prefilled" do
        assert page.has_text?("Title")
        assert page.has_field?("edition[title]", with: "Edit page title")
      end

      should "show Meta tag input box prefilled" do
        assert page.has_text?("Meta tag description")
        assert page.has_text?("Some search engines will display this if they cannot find what they need in the main text")
        assert page.has_field?("edition[overview]", with: "metatags")
      end

      should "show Beta content radios prechecked" do
        assert page.has_text?("Is this beta content?")
        assert find(".gem-c-radio input[value='0']")
        assert find(".gem-c-radio input[value='1']").checked?
      end

      should "show Body text field prefilled" do
        assert page.has_text?("Body")
        assert page.has_text?("Refer to the Govspeak guidance (opens in new tab)")
        assert page.has_field?("edition[body]", with: "The body")
      end

      should "not show Change Note field for an unpublished document" do
        assert page.has_no_text?("Add a public change note")
        assert page.has_no_text?("Telling users when published information has changed is important for transparency.")
        assert page.has_no_field?("edition[change_note]")
      end

      should "update and show success message" do
        fill_in "edition[title]", with: "Changed Title"
        fill_in "edition[overview]", with: "Changed Meta tag description"
        choose("Yes")
        fill_in "edition[body]", with: "Changed body"
        click_button("Save")

        assert page.has_field?("edition[title]", with: "Changed Title")
        assert page.has_field?("edition[overview]", with: "Changed Meta tag description")
        assert find(".gem-c-radio input[value='1']").checked?
        assert page.has_field?("edition[body]", with: "Changed body")
        assert page.has_text?("Edition updated successfully.")
      end

      context "user does not have editor permissions" do
        setup do
          login_as(FactoryBot.create(:user, name: "Non Editor"))
          visit_draft_edition
        end

        should "not show any editable components" do
          assert page.has_no_css?(".govuk-textarea")
          assert page.has_no_css?(".govuk-input")
          assert page.has_no_css?(".govuk-radios")
        end

        should "not show the send to 2i button" do
          assert page.has_no_link?("Send to 2i")
        end

        should "not show the Save button" do
          assert page.has_no_button?("Save")
        end

        should "show the Preview link" do
          assert page.has_link?("Preview (opens in new tab)")
        end
      end

      context "place edition" do
        setup do
          visit_draft_place_edition
        end

        should "show fields for place edition" do
          assert page.has_field?("edition[title]", with: "Edit page title")
          assert page.has_field?("edition[overview]", with: "metatags")

          assert page.has_css?(".govuk-label", text: "Places Manager service identifier")
          assert page.has_css?(".govuk-hint", text: "This is assigned in the Places Manager application")
          assert page.has_field?("edition[place_type]", with: "The place type")

          assert page.has_css?(".govuk-label", text: "Introduction")
          assert page.has_css?(".govuk-hint", text: "Refer to the Govspeak guidance (opens in new tab)")
          assert page.has_field?("edition[introduction]", with: "some intro")

          assert page.has_css?(".govuk-label", text: "Further information (optional)")
          assert page.has_field?("edition[more_information]", with: "some more info")

          assert page.has_css?(".govuk-label", text: "What you need to know (optional)")
          assert page.has_field?("edition[need_to_know]", with: "some need to know")

          assert find(".gem-c-radio input[value='1']").checked?
        end

        should "update place edition and show success message" do
          fill_in "edition[title]", with: "Changed Title"
          fill_in "edition[overview]", with: "Changed Meta tag description"
          fill_in "edition[place_type]", with: "Changed place type"
          fill_in "edition[introduction]", with: "Changed intro"
          fill_in "edition[more_information]", with: "Changed more info"
          fill_in "edition[need_to_know]", with: "Changed need to know"
          choose("Yes")
          click_button("Save")

          assert page.has_field?("edition[title]", with: "Changed Title")
          assert page.has_field?("edition[overview]", with: "Changed Meta tag description")
          assert page.has_field?("edition[place_type]", with: "Changed place type")
          assert page.has_field?("edition[introduction]", with: "Changed intro")
          assert page.has_field?("edition[more_information]", with: "Changed more info")
          assert page.has_field?("edition[need_to_know]", with: "Changed need to know")
          assert find(".gem-c-radio input[value='1']").checked?
          assert page.has_text?("Edition updated successfully.")
        end
      end

      context "local transaction edition" do
        setup do
          visit_draft_local_transaction_edition
        end

        should "show fields for local transaction edition" do
          assert page.has_field?("edition[title]", with: "Edit page title")

          assert page.has_css?(".govuk-label", text: "LGSL code")
          assert page.has_text?("9012")

          assert page.has_css?(".govuk-label", text: "LGIL code")
          assert page.has_field?("edition[lgil_code]", with: "23")

          assert page.has_css?(".govuk-label", text: "Button text (optional)")
          assert page.has_css?(".govuk-hint", text: "If left blank, the default text ‘Find your local council’ will be used")
          assert page.has_field?("edition[cta_text]", with: "Find your local council")

          assert page.has_css?(".govuk-label", text: "Introduction")
          assert page.has_css?(".govuk-hint", text: "Set the scene for the user. Explain that it’s the responsibility of the local council and that we’ll take you there. Read the Govspeak guidance (opens in new tab)")
          assert page.has_field?("edition[introduction]", with: "Test introduction")

          assert page.has_css?(".govuk-label", text: "Further information (optional)")
          assert page.has_field?("edition[more_information]", with: "some more info")

          assert page.has_css?(".govuk-label", text: "What you need to know (optional)")
          assert page.has_field?("edition[need_to_know]", with: "some need to know")

          assert page.has_css?(".govuk-label", text: "Above results content (optional)")
          assert page.has_field?("edition[before_results]", with: "before results")

          assert page.has_css?(".govuk-label", text: "Below results content (optional)")
          assert page.has_field?("edition[after_results]", with: "after results")

          within all(".govuk-fieldset")[0] do
            assert page.has_css?("legend", text: "Northern Ireland")
            assert find(".gem-c-radio input[value='local_authority_service']").checked?
          end

          within all(".govuk-fieldset")[1] do
            assert page.has_css?("legend", text: "Scotland")
            assert find(".gem-c-radio input[value='devolved_administration_service']").checked?

            assert page.has_css?(".govuk-label", text: "URL of the devolved administration website page")
            assert page.has_field?("edition[scotland_availability_attributes][alternative_url]", with: "https://www.google.com")
          end

          within all(".govuk-fieldset")[2] do
            assert page.has_css?("legend", text: "Wales")
            assert find(".gem-c-radio input[value='unavailable']").checked?
          end

          assert find(".gem-c-radio input[value='1']").checked?
        end

        should "update local transaction edition and show success message" do
          fill_in "edition[title]", with: "Changed Title"
          fill_in "edition[lgil_code]", with: "25"
          fill_in "edition[cta_text]", with: "Changed button text"
          fill_in "edition[introduction]", with: "Changed intro"
          fill_in "edition[more_information]", with: "Changed more info"
          fill_in "edition[need_to_know]", with: "Changed need to know"
          fill_in "edition[before_results]", with: "Changed above results"
          fill_in "edition[after_results]", with: "Changed below results"

          within all(".govuk-fieldset")[0] do
            choose("Service not available")
          end

          within all(".govuk-fieldset")[1] do
            choose("Service available from local council")
          end

          within all(".govuk-fieldset")[2] do
            choose("Service available from devolved administration (or a similar service is available)")
            fill_in "edition[wales_availability_attributes][alternative_url]", with: "https://www.google.com"
          end

          choose("Yes")

          click_button("Save")

          assert page.has_field?("edition[title]", with: "Changed Title")
          assert page.has_field?("edition[lgil_code]", with: "25")
          assert page.has_field?("edition[cta_text]", with: "Changed button text")
          assert page.has_field?("edition[introduction]", with: "Changed intro")
          assert page.has_field?("edition[more_information]", with: "Changed more info")
          assert page.has_field?("edition[need_to_know]", with: "Changed need to know")
          assert page.has_field?("edition[before_results]", with: "Changed above results")
          assert page.has_field?("edition[after_results]", with: "Changed below results")

          within all(".govuk-fieldset")[0] do
            assert page.has_css?("legend", text: "Northern Ireland")
            assert find(".gem-c-radio input[value='unavailable']").checked?
          end

          within all(".govuk-fieldset")[1] do
            assert page.has_css?("legend", text: "Scotland")
            assert find(".gem-c-radio input[value='local_authority_service']").checked?
          end

          within all(".govuk-fieldset")[2] do
            assert page.has_css?("legend", text: "Wales")
            assert find(".gem-c-radio input[value='devolved_administration_service']").checked?

            assert page.has_css?(".govuk-label", text: "URL of the devolved administration website page")
            assert page.has_field?("edition[wales_availability_attributes][alternative_url]", with: "https://www.google.com")
          end

          assert find(".gem-c-radio input[value='1']").checked?
          assert page.has_text?("Edition updated successfully.")
        end

        should "should show an error message when URL of the devolved administration is blank" do
          within all(".govuk-fieldset")[2] do
            choose("Service available from devolved administration (or a similar service is available)")
            fill_in "edition[wales_availability_attributes][alternative_url]", with: ""
          end

          click_button("Save")

          within all(".govuk-fieldset")[2] do
            assert page.has_css?("legend", text: "Wales")
            assert find(".gem-c-radio input[value='devolved_administration_service']").checked?

            assert page.has_text?("Enter the URL of the devolved administration website page")
          end
        end

        should "should show an error message when URL of the devolved administration is invalid" do
          within all(".govuk-fieldset")[2] do
            choose("Service available from devolved administration (or a similar service is available)")
            fill_in "edition[wales_availability_attributes][alternative_url]", with: "some text"
          end

          click_button("Save")

          within all(".govuk-fieldset")[2] do
            assert page.has_css?("legend", text: "Wales")
            assert find(".gem-c-radio input[value='devolved_administration_service']").checked?

            assert page.has_text?("Must be a full URL, starting with https://")
          end
        end

        should "should show an error message when LGIL code is blank" do
          fill_in "edition[lgil_code]", with: ""

          click_button("Save")

          assert page.has_text?("Enter a LGIL code")
        end

        should "should show an error message when LGIL code is invalid" do
          fill_in "edition[lgil_code]", with: "some text"

          click_button("Save")

          assert page.has_text?("LGIL code can only be a whole number between 0 and 999")
        end
      end

      context "guide edition" do
        setup do
          visit_draft_guide_edition
        end

        context "user has editor permissions" do
          should "show fields for guide edition" do
            assert page.has_field?("edition[title]", with: "Edit page title")
            assert page.has_field?("edition[overview]", with: "metatags")

            assert page.has_css?(".govuk-heading-m", text: "Chapters")
            assert page.has_css?(".govuk-button", text: "Add a new chapter")

            within all(".govuk-fieldset")[0] do
              assert page.has_css?("legend", text: "Is every chapter part of a step by step?")
              assert page.has_css?(".govuk-hint", text: "The chapter navigation will be hidden if they all are")
              assert find(".gem-c-radio input[value='1']").checked?
            end

            within all(".govuk-fieldset")[1] do
              assert page.has_css?("legend", text: "Is this beta content?")
              assert find(".gem-c-radio input[value='1']").checked?
            end
          end

          should "show guide chapter list for guide edition if present" do
            visit_draft_guide_edition_with_parts

            assert page.has_field?("edition[title]", with: "Edit page title")
            assert page.has_field?("edition[overview]", with: "metatags")

            assert page.has_css?(".govuk-heading-m", text: "Chapters")

            assert page.has_css?(".govuk-summary-list__row", text: "PART !")
            assert page.has_css?(".govuk-summary-list__row", text: "PART !!")
            assert page.has_css?(".govuk-summary-list__actions", text: "Edit", minimum: 2)

            assert page.has_css?(".govuk-button", text: "Add a new chapter")

            within all(".govuk-fieldset")[0] do
              assert page.has_css?("legend", text: "Is every chapter part of a step by step?")
              assert page.has_css?(".govuk-hint", text: "The chapter navigation will be hidden if they all are")
              assert find(".gem-c-radio input[value='1']").checked?
            end

            within all(".govuk-fieldset")[1] do
              assert page.has_css?("legend", text: "Is this beta content?")
              assert find(".gem-c-radio input[value='1']").checked?
            end
          end

          should "update guide edition and show success message" do
            fill_in "edition[title]", with: "Changed Title"
            fill_in "edition[overview]", with: "Changed Meta tag description"

            within all(".govuk-fieldset")[0] do
              choose("Yes")
            end

            within all(".govuk-fieldset")[1] do
              choose("Yes")
            end

            click_button("Save")

            assert page.has_field?("edition[title]", with: "Changed Title")
            assert page.has_field?("edition[overview]", with: "Changed Meta tag description")

            within all(".govuk-fieldset")[0] do
              assert page.has_css?("legend", text: "Is every chapter part of a step by step?")
              assert page.has_css?(".govuk-hint", text: "The chapter navigation will be hidden if they all are")
              assert find(".gem-c-radio input[value='1']").checked?
            end

            within all(".govuk-fieldset")[1] do
              assert page.has_css?("legend", text: "Is this beta content?")
              assert find(".gem-c-radio input[value='1']").checked?
            end

            assert page.has_text?("Edition updated successfully.")
          end

          should "show Add new chapter page when Add new chapter button is clicked" do
            click_link("Add a new chapter")

            assert page.has_content?("Add new chapter")

            assert page.has_css?(".govuk-label", text: "Title")
            assert page.has_css?(".govuk-label", text: "Slug")
            assert page.has_css?(".govuk-label", text: "Body")
          end

          should "show Edit chapter page when Edit chapter link is clicked" do
            visit_draft_guide_edition_with_parts

            within all(".govuk-summary-list__row").last do
              click_link("Edit")
            end
            assert page.has_content?("Edit chapter")

            assert page.has_field?("part[title]", with: "PART !!")
            assert page.has_field?("part[slug]", with: "part-two")
            assert page.has_field?("part[body]", with: "This is some more version text.")
          end

          should "not show 'Reorder chapters' button when no parts are present" do
            assert page.has_no_link?("Reorder chapters")
          end

          should "not show 'Reorder chapters' button when 1 part is present" do
            @draft_guide_edition.parts.build(
              title: "PART !",
              body: "This is some version text.",
              slug: "part-one",
              order: 1,
            )
            @draft_guide_edition.save!
            @draft_guide_edition.reload

            assert page.has_no_link?("Reorder chapters")
          end

          should "show an error if the user tries to directly access the reorder chapters page with less than two parts" do
            visit reorder_edition_guide_parts_path(@draft_guide_edition)

            assert current_path == edition_path(@draft_guide_edition.id)
            assert page.has_content?("You can only reorder chapters when there are at least 2.")
          end

          should "show 'Reorder chapters' button when two parts are present" do
            visit_draft_guide_edition_with_parts
            assert page.has_link?("Reorder chapters")
          end

          context "Add new chapter" do
            setup do
              click_link("Add a new chapter")
            end

            should "save and redirect to edit guide page when 'save and go to summary' button is clicked" do
              fill_in "Title", with: "Part One"
              fill_in "Slug", with: "part-one"
              fill_in "Body", with: "body-text"

              click_button("Save and go to summary")

              assert_current_path edition_path(@draft_guide_edition.id)

              assert page.has_content?("New chapter added successfully.")

              assert page.has_css?(".govuk-summary-list__row", text: "Part One")
            end

            should "show validation error when Title is empty" do
              fill_in "Title", with: ""
              fill_in "Slug", with: "part-one"
              fill_in "Body", with: "body-text"

              click_button("Save and go to summary")

              assert_current_path edition_guide_parts_path(@draft_guide_edition.id)

              assert page.has_field?("part[title]", with: "")
              assert page.has_field?("part[slug]", with: "part-one")
              assert page.has_field?("part[body]", with: "body-text")

              assert page.has_content?("Enter a title for Chapter 1")
            end

            should "show validation error when Slug is empty" do
              fill_in "Title", with: "Part one"
              fill_in "Slug", with: ""
              fill_in "Body", with: "body-text"

              click_button("Save and go to summary")

              assert_current_path edition_guide_parts_path(@draft_guide_edition.id)

              assert page.has_field?("part[title]", with: "Part one")
              assert page.has_field?("part[slug]", with: "")
              assert page.has_field?("part[body]", with: "body-text")

              assert page.has_content?("Enter a slug for Chapter 1")
            end

            should "show validation error when Slug is invalid" do
              fill_in "Title", with: "Part one"
              fill_in "Slug", with: "@"
              fill_in "Body", with: "body-text"

              click_button("Save and go to summary")

              assert_current_path edition_guide_parts_path(@draft_guide_edition.id)

              assert page.has_field?("part[title]", with: "Part one")
              assert page.has_field?("part[slug]", with: "@")
              assert page.has_field?("part[body]", with: "body-text")

              assert page.has_content?("Slug can only consist of lower case characters, numbers and hyphens")
            end

            should "redirect to guide edit page when back to summary link is clicked" do
              click_link("Back to summary")

              assert_current_path edition_path(@draft_guide_edition.id)

              assert page.has_content?("Edit")
            end

            should "display the guide edit page when the 'Cancel and discard changes' link is clicked" do
              click_link("Cancel and discard changes")

              assert_current_path edition_path(@draft_guide_edition.id)

              assert page.has_content?("Edit")
            end
          end

          context "Reorder Chapters" do
            setup do
              visit_draft_guide_edition_with_parts
              click_link("Reorder chapters")
            end

            should "reorder chapters and redirect to guide edit page when update order is clicked" do
              within all(".gem-c-reorderable-list__item")[0] do
                fill_in "Position", with: "2"
              end
              within all(".gem-c-reorderable-list__item")[1] do
                fill_in "Position", with: "1"
              end

              click_button "Update order"

              within all(".govuk-summary-list__row")[3] do
                assert page.has_text?("PART !!")
              end
              within all(".govuk-summary-list__row")[4] do
                assert page.has_text?("PART !")
              end
            end

            should "not reorder chapters and redirect to guide edit page when cancel is clicked" do
              within all(".gem-c-reorderable-list__item")[0] do
                fill_in "Position", with: "2"
              end
              within all(".gem-c-reorderable-list__item")[1] do
                fill_in "Position", with: "1"
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

          %w[scheduled_for_publishing published archived].each do |state|
            context "when state is #{state}" do
              setup do
                visit_draft_guide_edition_with_parts(state: state)
              end

              should "not show 'Add new chapter' button" do
                assert_not page.has_css?(".govuk-button", text: "Add a new chapter")
              end

              should "not show 'Reorder chapters' button even with two parts present" do
                assert page.has_no_link?("Reorder chapters")
              end

              should "not allow user to load reorder chapters page" do
                visit reorder_edition_guide_parts_path(@draft_guide_edition_with_parts)

                assert current_path == edition_path(@draft_guide_edition_with_parts.id)
                assert page.has_content?("You are not allowed to perform this action in the current state.")
              end
            end
          end

          context "Edit chapter" do
            setup do
              visit_draft_guide_edition_with_parts
              @part_id = @draft_guide_edition_with_parts.parts.last.id
              within all(".govuk-summary-list__row").last do
                click_link("Edit")
              end
            end

            should "save and redirect to edit guide page when save and summary button is clicked" do
              fill_in "Title", with: "PART !!!"
              fill_in "Slug", with: "part-two"
              fill_in "Body", with: "body-text"

              click_button("Save and go to summary")

              assert_current_path edition_path(@draft_guide_edition_with_parts.id)

              assert page.has_content?("Chapter updated successfully.")

              assert page.has_css?(".govuk-summary-list__row", text: "PART !!!")
            end

            should "show validation error when Title is empty" do
              fill_in "Title", with: ""
              fill_in "Slug", with: "part-two"
              fill_in "Body", with: "body-text"

              click_button("Save and go to summary")

              assert_current_path edition_guide_part_path(@draft_guide_edition_with_parts.id, @part_id)

              assert page.has_field?("part[title]", with: "")
              assert page.has_field?("part[slug]", with: "part-two")
              assert page.has_field?("part[body]", with: "body-text")

              assert page.has_content?("Enter a title for Chapter 2")
            end

            should "show validation error when Slug is empty" do
              fill_in "Title", with: "Part two"
              fill_in "Slug", with: ""
              fill_in "Body", with: "body-text"

              click_button("Save and go to summary")

              assert_current_path edition_guide_part_path(@draft_guide_edition_with_parts.id, @part_id)

              assert page.has_field?("part[title]", with: "Part two")
              assert page.has_field?("part[slug]", with: "")
              assert page.has_field?("part[body]", with: "body-text")

              assert page.has_content?("Enter a slug for Chapter 2")
            end

            should "show validation error when Slug is invalid" do
              fill_in "Title", with: "Part two"
              fill_in "Slug", with: "@"
              fill_in "Body", with: "body-text"

              click_button("Save and go to summary")

              assert_current_path edition_guide_part_path(@draft_guide_edition_with_parts.id, @part_id)

              assert page.has_field?("part[title]", with: "Part two")
              assert page.has_field?("part[slug]", with: "@")
              assert page.has_field?("part[body]", with: "body-text")

              assert page.has_content?("Slug can only consist of lower case characters, numbers and hyphens")
            end

            should "redirect to guide edit page when back to summary link is clicked" do
              click_link("Back to summary")

              assert_current_path edition_path(@draft_guide_edition_with_parts.id)

              assert page.has_content?("Edit")
            end

            should "display the Delete chapter confirmation page when the 'Delete chapter' link is clicked" do
              click_link("Delete chapter")

              assert_current_path confirm_destroy_edition_guide_part_path(@draft_guide_edition_with_parts.id, @part_id)
              assert page.has_content?("Are you sure you want to delete this chapter?")
            end
          end
        end

        context "user has no editor permissions" do
          setup do
            login_as(FactoryBot.create(:user, name: "Non Editor"))
            visit_draft_guide_edition_with_parts
          end

          should "not show 'Add new chapter' button" do
            assert_not page.has_css?(".govuk-button", text: "Add a new chapter")
          end

          should "not show 'Reorder chapters' button even with two parts present" do
            assert page.has_no_link?("Reorder chapters")
          end

          should "not allow user to load reorder chapters page" do
            visit reorder_edition_guide_parts_path(@draft_guide_edition_with_parts)

            assert current_path == edition_path(@draft_guide_edition_with_parts.id)
            assert page.has_content?("You do not have correct editor permissions for this action.")
          end

          should "not show the 'Delete chapter' button'" do
            assert page.has_no_link?("Delete chapter")
          end
        end

        context "Delete chapter confirmation" do
          setup do
            create_draft_guide_edition_with_parts
            @part = @draft_guide_edition_with_parts.parts.last
            visit confirm_destroy_edition_guide_part_path(@draft_guide_edition_with_parts, @part)
          end

          should "redirect to edit guide page and show a success message when the 'Delete chapter' button is clicked" do
            click_button("Delete chapter")

            @draft_guide_edition_with_parts.reload
            assert_current_path edition_path(@draft_guide_edition_with_parts.id)
            assert page.has_content?("Chapter deleted successfully")
            assert @draft_guide_edition_with_parts.parts.exclude? @part
          end

          should "direct the user to the edit chapter page when the 'Cancel' button is clicked" do
            click_link("Cancel")

            assert_current_path edit_edition_guide_part_path(@draft_guide_edition_with_parts, @part)
          end
        end
      end

      context "transaction edition" do
        setup do
          visit_transaction_edition(state: "draft", in_beta: true)
        end

        should "show fields for transaction edition" do
          assert page.has_field?("edition[title]", with: "Edit page title")
          assert page.has_css?(".govuk-label", text: "Title")

          assert page.has_field?("edition[overview]", with: "metatags")
          assert page.has_css?(".govuk-label", text: "Meta tag description")
          assert page.has_css?(".govuk-hint", text: "Some search engines will display this if they cannot find what they need in the main text")

          assert page.has_field?("edition[introduction]", with: "Transaction introduction")
          assert page.has_css?(".govuk-label", text: "Introduction")
          assert page.has_css?(".govuk-hint", text: "Set the scene for the user. What is about to happen? For example, “you will need to fill in a form, print it out and take it to the post office”. Refer to the Govspeak guidance (opens in new tab)")

          assert page.has_field?("edition[start_button_text]")
          assert page.has_text?("Start button text")
          assert find(".gem-c-radio input[value='Start now']").checked?

          assert page.has_field?("edition[will_continue_on]", with: "To be continued...")
          assert page.has_css?(".govuk-label", text: "Text below the start button (optional)")
          assert page.has_css?(".govuk-hint", text: "Following ‘on’, for example “the HMRC website”")

          assert page.has_field?("edition[link]", with: "https://continue.com")
          assert page.has_css?(".govuk-label", text: "Link to start of transaction")
          assert page.has_css?(".govuk-hint", text: "Link as deep as possible")

          assert page.has_field?("edition[more_information]", with: "Transaction more information")
          assert page.has_css?(".govuk-label", text: "More information (optional)")

          assert page.has_field?("edition[alternate_methods]", with: "Method A or B")
          assert page.has_css?(".govuk-label", text: "Other ways to apply (optional)")
          assert page.has_css?(".govuk-hint", text: "Alternative ways of completing this transaction")

          assert page.has_field?("edition[need_to_know]", with: "Transaction need to")
          assert page.has_css?(".govuk-label", text: "What you need to know (optional)")

          assert page.has_field?("edition[in_beta]")
          assert page.has_text?("Is this beta content?")
          assert find(".gem-c-radio input[value='1']").checked?
        end

        should "update transaction edition and show success message" do
          fill_in "edition[title]", with: "Changed Title"
          fill_in "edition[overview]", with: "Changed Meta tag description"
          fill_in "edition[introduction]", with: "Changed intro"
          choose("Sign in")
          fill_in "edition[will_continue_on]", with: "Continue on changed"
          fill_in "edition[link]", with: "https://changed.com"
          fill_in "edition[more_information]", with: "Changed more info"
          fill_in "edition[alternate_methods]", with: "Method C or D"
          fill_in "edition[need_to_know]", with: "Changed need to"
          choose("Yes")
          click_button("Save")

          assert page.has_field?("edition[title]", with: "Changed Title")
          assert page.has_field?("edition[overview]", with: "Changed Meta tag description")
          assert page.has_field?("edition[introduction]", with: "Changed intro")
          assert find(".gem-c-radio input[value='Sign in']").checked?
          assert page.has_field?("edition[will_continue_on]", with: "Continue on changed")
          assert page.has_field?("edition[link]", with: "https://changed.com")
          assert page.has_field?("edition[more_information]", with: "Changed more info")
          assert page.has_field?("edition[alternate_methods]", with: "Method C or D")
          assert page.has_field?("edition[need_to_know]", with: "Changed need to")
          assert find(".gem-c-radio input[value='1']").checked?
          assert page.has_text?("Edition updated successfully.")
        end
      end

      context "completed transaction edition" do
        should "show correct fields for no promotion" do
          visit_completed_transaction_edition(state: "draft", in_beta: true)

          assert page.has_field?("edition[title]", with: "Edit page title")
          assert page.has_css?(".govuk-label", text: "Title")

          assert page.has_field?("edition[overview]", with: "metatags")
          assert page.has_css?(".govuk-label", text: "Meta tag description")
          assert page.has_css?(".govuk-hint", text: "Some search engines will display this if they cannot find what they need in the main text")

          assert page.has_text?("Promotions")
          assert page.has_css?(".govuk-hint", text: "Display a promotion above the satisfaction survey")

          assert page.has_checked_field?("edition[promotion_choice]", with: "none")

          assert page.has_field?("edition[in_beta]")
          assert page.has_text?("Is this beta content?")
          assert page.has_checked_field?("edition[in_beta]", with: "1")
        end

        should "show correct fields for organ donation" do
          visit_completed_transaction_edition(
            state: "draft",
            choice: "organ_donor",
            url: "https://example.com",
            opt_in_url: "https://opt-in.com",
            opt_out_url: "https://opt-out.com",
          )

          assert page.has_checked_field?("edition[promotion_choice]", with: "organ_donor")

          assert page.has_css?(".govuk-label", text: "Promotion URL")
          assert page.has_field?("edition[promotion_choice_url_organ_donor]", with: "https://example.com")

          assert page.has_css?(".govuk-label", text: "Opt-in URL (optional)")
          assert page.has_field?("edition[promotion_choice_opt_in_url]", with: "https://opt-in.com")

          assert page.has_css?(".govuk-label", text: "Opt-out URL (optional)")
          assert page.has_field?("edition[promotion_choice_opt_out_url]", with: "https://opt-out.com")
        end

        should "show correct fields for photo ID" do
          visit_completed_transaction_edition(state: "draft", choice: "bring_id_to_vote", url: "https://example.com")

          assert page.has_checked_field?("edition[promotion_choice]", with: "bring_id_to_vote")

          assert page.has_css?(".govuk-label", text: "Promotion URL")
          assert page.has_field?("edition[promotion_choice_url_bring_id_to_vote]", with: "https://example.com")
        end

        should "show correct fields for MOT reminder" do
          visit_completed_transaction_edition(state: "draft", choice: "mot_reminder", url: "https://example.com")

          assert page.has_checked_field?("edition[promotion_choice]", with: "mot_reminder")

          assert page.has_css?(".govuk-label", text: "Promotion URL")
          assert page.has_field?("edition[promotion_choice_url_mot_reminder]", with: "https://example.com")
        end

        should "show correct fields for electric vehicles" do
          visit_completed_transaction_edition(state: "draft", choice: "electric_vehicle", url: "https://example.com")

          assert page.has_checked_field?("edition[promotion_choice]", with: "electric_vehicle")

          assert page.has_css?(".govuk-label", text: "Promotion URL")
          assert page.has_field?("edition[promotion_choice_url_electric_vehicle]", with: "https://example.com")
        end

        should "amend fields and show success message when edition is updated" do
          visit_completed_transaction_edition(state: "draft", in_beta: true)

          fill_in "edition[title]", with: "Changed Title"
          fill_in "edition[overview]", with: "Changed Meta tag description"
          choose("Organ donation")
          fill_in "edition[promotion_choice_url_organ_donor]", with: "https://organ.com"
          fill_in "edition[promotion_choice_opt_in_url]", with: "https://organ_opt_in.com"
          fill_in "edition[promotion_choice_opt_out_url]", with: "https://organ_opt_out.com"
          choose("Yes")
          click_button("Save")

          assert page.has_field?("edition[title]", with: "Changed Title")
          assert page.has_field?("edition[overview]", with: "Changed Meta tag description")
          assert page.has_field?("edition[promotion_choice_url_organ_donor]", with: "https://organ.com")
          assert page.has_field?("edition[promotion_choice_url_bring_id_to_vote]", with: "")
          assert page.has_field?("edition[promotion_choice_url_mot_reminder]", with: "")
          assert page.has_field?("edition[promotion_choice_url_electric_vehicle]", with: "")
          assert page.has_field?("edition[promotion_choice_opt_in_url]", with: "https://organ_opt_in.com")
          assert page.has_field?("edition[promotion_choice_opt_out_url]", with: "https://organ_opt_out.com")
          assert page.has_checked_field?("edition[promotion_choice]", with: "organ_donor")
          assert page.has_checked_field?("edition[in_beta]", with: "1")
          assert page.has_text?("Edition updated successfully.")

          choose("Bring photo ID to vote")
          fill_in "edition[promotion_choice_url_bring_id_to_vote]", with: "https://photo.com"
          click_button("Save")

          assert page.has_field?("edition[promotion_choice_url_bring_id_to_vote]", with: "https://photo.com")
          assert page.has_field?("edition[promotion_choice_url_organ_donor]", with: "")
          assert page.has_field?("edition[promotion_choice_opt_in_url]", with: "")
          assert page.has_field?("edition[promotion_choice_opt_out_url]", with: "")
          assert page.has_checked_field?("edition[promotion_choice]", with: "bring_id_to_vote")

          choose("MOT reminders")
          fill_in "edition[promotion_choice_url_mot_reminder]", with: "https://mot.com"
          click_button("Save")

          assert page.has_field?("edition[promotion_choice_url_bring_id_to_vote]", with: "")
          assert page.has_field?("edition[promotion_choice_url_mot_reminder]", with: "https://mot.com")
          assert page.has_checked_field?("edition[promotion_choice]", with: "mot_reminder")

          choose("Electric vehicles")
          fill_in "edition[promotion_choice_url_electric_vehicle]", with: "https://electric.com"
          click_button("Save")

          assert page.has_field?("edition[promotion_choice_url_mot_reminder]", with: "")
          assert page.has_field?("edition[promotion_choice_url_electric_vehicle]", with: "https://electric.com")
          assert page.has_checked_field?("edition[promotion_choice]", with: "electric_vehicle")
        end

        should "raise an error and not save changes if Promotion URL is not filled out" do
          ["Organ donation", "Bring photo ID to vote", "MOT reminders", "Electric vehicles"].each do |promotion_choice|
            visit_completed_transaction_edition(state: "draft")

            choose(promotion_choice)
            click_button("Save")

            assert page.has_css?(".gem-c-error-summary__list-item", text: "Enter a promotion URL")
            assert page.has_css?(".govuk-error-message", text: "Enter a promotion URL")
            assert page.has_css?(".govuk-input--error")
          end
        end
      end
    end

    context "amends needed edition of a new publication" do
      should "show 'Send to 2i' link" do
        visit_amends_needed_edition
        assert page.has_link?("Send to 2i")
      end

      should "show Preview link" do
        visit_amends_needed_edition
        assert page.has_link?("Preview (opens in new tab)")
      end

      context "user does not have editor permissions" do
        setup do
          login_as(FactoryBot.create(:user, name: "Non Editor"))
          visit_amends_needed_edition
        end

        should "not show any editable components" do
          assert page.has_no_css?(".govuk-textarea")
          assert page.has_no_css?(".govuk-input")
          assert page.has_no_css?(".govuk-radios")
        end

        should "not show the send to 2i button" do
          assert page.has_no_link?("Send to 2i")
        end

        should "not show the Save button" do
          assert page.has_no_button?("Save")
        end

        should "show the Preview link" do
          assert page.has_link?("Preview (opens in new tab)")
        end
      end
    end

    context "draft edition of a previously published publication" do
      setup do
        visit_new_edition_of_published_edition
      end

      should "show Change Note field for a new edition of a published document" do
        find("details").click
        find("input[name='edition[major_change]'][value='true']").choose

        assert page.has_text?("Add a public change note")
        assert page.has_text?("Telling users when published information has changed is important for transparency.")
        assert page.has_field?("edition[change_note]")
      end
    end

    context "ready edition" do
      setup do
        visit_ready_edition
      end

      context "user is a govuk editor" do
        should "show a 'Schedule' button in the sidebar" do
          assert page.has_link?("Schedule")
        end

        should "show Preview link" do
          assert page.has_link?("Preview (opens in new tab)")
        end
      end

      context "user is not a govuk editor" do
        setup do
          login_as(FactoryBot.create(:user))
          visit_ready_edition
        end

        should "not show a 'Schedule' button in the sidebar" do
          assert page.has_no_button?("Schedule")
        end
      end

      context "edition is welsh" do
        setup do
          @welsh_edition = FactoryBot.create(
            :answer_edition, :welsh, state: "ready"
          )
        end

        context "user is a welsh editor" do
          setup do
            login_as_welsh_editor
            visit edition_path(@welsh_edition)
          end

          should "show a 'Schedule' button in the sidebar" do
            assert page.has_link?("Schedule")
          end
        end

        context "user is not a welsh editor" do
          setup do
            login_as(FactoryBot.create(:user))
            visit edition_path(@welsh_edition)
          end

          should "not show a 'Schedule' button in the sidebar" do
            assert page.has_no_button?("Schedule")
          end
        end
      end

      should "navigate to the 'Schedule publication' page when the 'Schedule' button is clicked" do
        click_link("Schedule")

        assert_current_path schedule_page_edition_path(@ready_edition.id)
      end

      context "user does not have editor permissions" do
        setup do
          login_as(FactoryBot.create(:user, name: "Non Editor"))
          visit_ready_edition
        end

        should "not show any editable components" do
          assert page.has_no_css?(".govuk-textarea")
          assert page.has_no_css?(".govuk-input")
          assert page.has_no_css?(".govuk-radios")
        end

        should "not show the Save button" do
          assert page.has_no_button?("Save")
        end

        should "show the Preview link" do
          assert page.has_link?("Preview (opens in new tab)")
        end
      end
    end

    context "Schedule page" do
      setup do
        create_ready_edition
        visit schedule_page_edition_path(@ready_edition.id)
      end

      should "render the 'Schedule' page" do
        within :css, ".gem-c-heading" do
          assert page.has_css?("h1", text: "Schedule publication")
          assert page.has_css?(".gem-c-heading__context", text: @ready_edition.title)
        end

        within :css, ".gem-c-textarea" do
          assert page.has_css?("label", text: "Comment (optional)")
          assert page.has_css?("textarea")
        end

        within all(".govuk-fieldset")[0] do
          assert page.has_css?("legend", text: "Publication date")
          assert page.has_css?(".govuk-label", text: "Day")
          assert page.has_css?("input[name='publish_at_3i']")
          assert page.has_css?(".govuk-label", text: "Month")
          assert page.has_css?("input[name='publish_at_2i']")
          assert page.has_css?(".govuk-label", text: "Year")
          assert page.has_css?("input[name='publish_at_1i']")
        end

        within all(".govuk-fieldset")[1] do
          assert page.has_css?("legend", text: "Publication time")
          assert page.has_css?(".govuk-label", text: "Hour")
          assert page.has_css?("input[name='publish_at_4i'][value='00']")
          assert page.has_css?(".govuk-label", text: "Minute")
          assert page.has_css?("input[name='publish_at_5i'][value='01']")
        end

        assert page.has_button?("Schedule")
        assert page.has_link?("Cancel")
      end

      should "generate a date hint test 3 months in the future" do
        travel_to Time.zone.local(2025, 10, 1, 0, 0, 0)
        visit schedule_page_edition_path(@ready_edition.id)

        assert page.has_css?(".govuk-hint", text: "For example, 1 1 2026")
      end

      should "redirect to edit tab when Cancel button is pressed on Send to 2i page" do
        click_link("Cancel")

        assert_current_path edition_path(@ready_edition.id)
      end

      should "show success message and redirect back to the edit tab on submit" do
        date = 1.day.from_now

        fill_in "Day", with: date.day
        fill_in "Month", with: date.month
        fill_in "Year", with: date.year
        fill_in "Hour", with: date.hour
        fill_in "Minute", with: date.min

        click_button "Schedule"

        assert_current_path edition_path(@ready_edition.id)
        assert page.has_text?("Scheduled to publish at #{date.to_fs(:govuk_date)}")
      end
    end

    context "scheduled_for_publishing edition" do
      should "show common content-type fields" do
        edition = FactoryBot.create(
          :edition,
          state: "scheduled_for_publishing",
          title: "Some test title",
          overview: "Some overview text",
          in_beta: true,
          publish_at: Time.zone.now + 1.day,
        )
        visit edition_path(edition)

        assert page.has_css?("h3", text: "Title")
        assert page.has_css?("p", text: edition.title)
        assert page.has_css?("h3", text: "Meta tag description")
        assert page.has_css?("p", text: edition.overview)
        assert page.has_css?("h3", text: "Is this beta content?")
        assert page.has_css?("p", text: "Yes")

        edition.in_beta = false
        edition.save!(validate: false)
        visit edition_path(edition)
        assert page.has_css?("p", text: "No")
      end

      should "show body field" do
        edition = FactoryBot.create(
          :answer_edition,
          state: "scheduled_for_publishing",
          body: "## Some body text",
          publish_at: Time.zone.now + 1.day,
        )
        visit edition_path(edition)

        assert page.has_css?("h3", text: "Body")
        assert page.has_css?("div", text: edition.body)
      end

      should "show public change field" do
        edition = FactoryBot.create(
          :answer_edition,
          state: "scheduled_for_publishing",
          in_beta: true,
          major_change: false,
          publish_at: Time.zone.now + 1.day,
        )
        visit edition_path(edition)

        assert page.has_css?("h3", text: "Public change note")
        assert page.has_css?("p", text: "None added")

        edition.major_change = true
        edition.change_note = "Change note for test"
        edition.save!(validate: false)
        visit edition_path(edition)

        assert page.has_text?(edition.change_note)
      end

      should "show a preview link in the sidebar" do
        visit_scheduled_for_publishing_edition
        assert page.has_link?("Preview (opens in new tab)")
      end

      should "show a preview link when user is not an editor" do
        login_as(FactoryBot.create(:user, name: "Non Editor"))
        visit_scheduled_for_publishing_edition
        assert page.has_link?("Preview (opens in new tab)")
      end

      should "show a 'publish now' button in the sidebar when user is a govuk editor" do
        edition = FactoryBot.create(
          :edition, state: "scheduled_for_publishing", publish_at: Time.zone.now + 1.hour
        )
        login_as_govuk_editor

        visit edition_path(edition)

        assert page.has_link?("Publish now", href: send_to_publish_page_edition_path(edition))
      end

      should "show a 'cancel scheduling' button in the sidebar when user is a govuk editor" do
        edition = FactoryBot.create(
          :edition, state: "scheduled_for_publishing", publish_at: Time.zone.now + 1.hour
        )
        login_as_govuk_editor

        visit edition_path(edition)

        assert page.has_link?("Cancel scheduling", href: cancel_scheduled_publishing_page_edition_path(edition))
      end

      context "that is welsh" do
        should "show a 'publish now' button in the sidebar when user is a welsh editor" do
          edition = FactoryBot.create(
            :edition, :welsh, state: "scheduled_for_publishing", publish_at: Time.zone.now + 1.hour
          )
          login_as_welsh_editor

          visit edition_path(edition)

          assert page.has_link?("Publish now", href: send_to_publish_page_edition_path(edition))
        end

        should "not show a 'publish now' button in the sidebar when user is not a welsh editor" do
          edition = FactoryBot.create(
            :edition, :welsh, state: "scheduled_for_publishing", publish_at: Time.zone.now + 1.hour
          )
          login_as(FactoryBot.create(:user))

          visit edition_path(edition)

          assert page.has_no_link?("Publish now")
        end

        should "show a 'cancel scheduling' button in the sidebar when user is a welsh editor" do
          edition = FactoryBot.create(
            :edition, :welsh, state: "scheduled_for_publishing", publish_at: Time.zone.now + 1.hour
          )
          login_as_welsh_editor

          visit edition_path(edition)

          assert page.has_link?("Cancel scheduling", href: cancel_scheduled_publishing_page_edition_path(edition))
        end

        should "not show a 'cancel scheduling' button in the sidebar when user is not a welsh editor" do
          edition = FactoryBot.create(
            :edition, :welsh, state: "scheduled_for_publishing", publish_at: Time.zone.now + 1.hour
          )
          login_as(FactoryBot.create(:user))

          visit edition_path(edition)

          assert page.has_no_link?("Cancel scheduling")
        end
      end

      context "place edition" do
        should "show public change note field" do
          edition = FactoryBot.create(
            :place_edition,
            state: "scheduled_for_publishing",
            in_beta: true,
            major_change: false,
            publish_at: Time.zone.now + 1.day,
          )
          visit edition_path(edition)

          assert page.has_css?("h3", text: "Public change note")
          assert page.has_css?("p", text: "None added")

          edition.major_change = true
          edition.change_note = "Change note for test"
          edition.save!(validate: false)
          visit edition_path(edition)

          assert page.has_text?(edition.change_note)
        end
      end

      context "transaction edition" do
        should "show public change note field" do
          visit_transaction_edition(state: "scheduled_for_publishing")

          assert page.has_css?("h3", text: "Public change note")
          assert page.has_css?("p", text: "None added")

          @transaction_edition.major_change = true
          @transaction_edition.change_note = "Change note for test"
          @transaction_edition.save!(validate: false)
          visit edition_path(@transaction_edition)

          assert page.has_text?(@transaction_edition.change_note)
        end
      end

      context "completed transaction edition" do
        should "show public change note field" do
          visit_completed_transaction_edition(state: "scheduled_for_publishing")

          assert page.has_css?("h3", text: "Public change note")
          assert page.has_css?("p", text: "None added")

          @completed_transaction_edition.major_change = true
          @completed_transaction_edition.change_note = "Change note for test"
          @completed_transaction_edition.save!(validate: false)
          visit edition_path(@completed_transaction_edition)

          assert page.has_text?(@completed_transaction_edition.change_note)
        end
      end
    end

    context "published edition" do
      should "show common content-type fields" do
        published_edition = FactoryBot.create(
          :edition,
          state: "published",
          title: "Some test title",
          overview: "Some overview text",
          in_beta: true,
        )
        visit edition_path(published_edition)

        assert page.has_css?("h3", text: "Title")
        assert page.has_css?("p", text: published_edition.title)
        assert page.has_css?("h3", text: "Meta tag description")
        assert page.has_css?("p", text: published_edition.overview)
        assert page.has_css?("h3", text: "Is this beta content?")
        assert page.has_css?("p", text: "Yes")

        published_edition.in_beta = false
        published_edition.save!(validate: false)
        visit edition_path(published_edition)
        assert page.has_css?("p", text: "No")
      end

      should "show body field" do
        published_edition = FactoryBot.create(
          :edition,
          state: "published",
          body: "## Some body text",
        )
        visit edition_path(published_edition)

        assert page.has_css?("h3", text: "Body")
        assert page.has_css?("div", text: published_edition.body)
      end

      should "show public change field" do
        published_edition = FactoryBot.create(
          :edition,
          state: "published",
          in_beta: true,
          major_change: false,
        )
        visit edition_path(published_edition)

        assert page.has_css?("h3", text: "Public change note")
        assert page.has_css?("p", text: "None added")

        published_edition.major_change = true
        published_edition.change_note = "Change note for test"
        published_edition.save!(validate: false)
        visit edition_path(published_edition)

        assert page.has_text?(published_edition.change_note)
      end

      context "place edition" do
        should "show published place edition fields as read only" do
          published_place_edition = FactoryBot.create(
            :place_edition,
            state: "published",
            title: "Some test title",
            overview: "Some overview text",
            place_type: "Some place type",
            introduction: "Some introduction",
            more_information: "Some more info",
            need_to_know: "Some need info",
            in_beta: true,
          )
          visit edition_path(published_place_edition)

          assert page.has_css?("h3", text: "Title")
          assert page.has_css?("p", text: published_place_edition.title)
          assert page.has_css?("h3", text: "Meta tag description")
          assert page.has_css?("p", text: published_place_edition.overview)
          assert page.has_css?("h3", text: "Places Manager service identifier")
          assert page.has_css?("p", text: published_place_edition.place_type)
          assert page.has_css?("h3", text: "Introduction")
          assert page.has_css?("p", text: published_place_edition.introduction)
          assert page.has_css?("h3", text: "Further information (optional)")
          assert page.has_css?("p", text: published_place_edition.more_information)
          assert page.has_css?("h3", text: "What you need to know (optional)")
          assert page.has_css?("p", text: published_place_edition.need_to_know)
          assert page.has_css?("h3", text: "Is this beta content?")
          assert page.has_css?("p", text: "Yes")
          assert page.has_css?("h3", text: "Public change note")
          assert page.has_css?("p", text: "None added")

          published_place_edition.in_beta = false
          published_place_edition.save!(validate: false)
          visit edition_path(published_place_edition)
          assert page.has_css?("p", text: "No")
        end

        should "show 'None added' for empty fields in place edition" do
          [nil, ""].each do |empty_value|
            empty_place_edition = FactoryBot.create(
              :place_edition,
              state: "published",
              title: "Edit page title",
              overview: empty_value,
              place_type: empty_value,
              introduction: empty_value,
              more_information: empty_value,
              need_to_know: empty_value,
              in_beta: true,
            )
            visit edition_path(empty_place_edition)

            assert page.has_css?("p", text: "None added", count: 6)
          end
        end
      end

      context "local transaction edition" do
        should "show published local transaction edition fields as read only" do
          @local_service = FactoryBot.create(:local_service, lgsl_code: 9012, description: "Whatever", providing_tier: %w[district unitary county])
          scotland_availability = FactoryBot.build(:scotland_availability, authority_type: "devolved_administration_service", alternative_url: "https://www.google.com")
          wales_availability = FactoryBot.build(:wales_availability, authority_type: "unavailable")
          published_local_transaction_edition = FactoryBot.create(
            :local_transaction_edition,
            state: "published",
            title: "Some test title",
            lgsl_code: @local_service.lgsl_code,
            panopticon_id: FactoryBot.create(:artefact).id,
            lgil_code: 23,
            cta_text: "Some cta text",
            introduction: "Some introduction",
            more_information: "Some more info",
            need_to_know: "Some need info",
            before_results: "Some above results",
            after_results: "Some below results",
            scotland_availability:,
            wales_availability:,
            in_beta: true,
          )
          visit edition_path(published_local_transaction_edition)

          assert page.has_css?("h3", text: "Title")
          assert page.has_css?("p", text: published_local_transaction_edition.title)
          assert page.has_css?("h3", text: "LGSL code")
          assert page.has_css?("p", text: published_local_transaction_edition.lgsl_code)
          assert page.has_css?("h3", text: "LGIL code")
          assert page.has_css?("p", text: published_local_transaction_edition.lgil_code)

          assert page.has_css?("h3", text: "Introduction")
          assert page.has_css?("p", text: published_local_transaction_edition.introduction)
          assert page.has_css?("h3", text: "Further information (optional)")
          assert page.has_css?("p", text: published_local_transaction_edition.more_information)
          assert page.has_css?("h3", text: "What you need to know (optional)")
          assert page.has_css?("p", text: published_local_transaction_edition.need_to_know)
          assert page.has_css?("h3", text: "Above results content (optional)")
          assert page.has_css?("p", text: published_local_transaction_edition.before_results)
          assert page.has_css?("h3", text: "Below results content (optional)")
          assert page.has_css?("p", text: published_local_transaction_edition.after_results)
          assert page.has_css?("h3", text: "Northern Ireland")
          assert page.has_css?("p", text: "Service available from local council")
          assert page.has_css?("h3", text: "Scotland")
          assert page.has_css?("p", text: "Service available from devolved administration (or a similar service is available)")
          assert page.has_css?("h3", text: "URL of the devolved administration website page")
          assert page.has_css?("p", text: "https://www.google.com")
          assert page.has_css?("h3", text: "Wales")
          assert page.has_css?("p", text: "Service not available")
          assert page.has_css?("h3", text: "Is this beta content?")
          assert page.has_css?("p", text: "Yes")
          assert page.has_css?("h3", text: "Public change note")
          assert page.has_css?("p", text: "None added")

          published_local_transaction_edition.in_beta = false
          published_local_transaction_edition.save!(validate: false)
          visit edition_path(published_local_transaction_edition)
          assert page.has_css?("p", text: "No")
        end

        should "show 'None added' for empty fields in local transaction edition" do
          @local_service = FactoryBot.create(:local_service, lgsl_code: 9012, description: "Whatever", providing_tier: %w[district unitary county])
          [nil, ""].each do |empty_value|
            empty_local_transaction_edition = FactoryBot.create(
              :local_transaction_edition,
              state: "published",
              title: "Edit page title",
              lgsl_code: @local_service.lgsl_code,
              panopticon_id: FactoryBot.create(:artefact).id,
              lgil_code: 35,
              cta_text: empty_value,
              introduction: empty_value,
              more_information: empty_value,
              need_to_know: empty_value,
              before_results: empty_value,
              after_results: empty_value,
              in_beta: true,
            )
            visit edition_path(empty_local_transaction_edition)

            assert page.has_css?("p", text: "None added", count: 7)
          end
        end
      end

      context "guide edition" do
        should "show published guide edition fields as read only" do
          published_guide_edition = FactoryBot.create(
            :guide_edition,
            state: "published",
            title: "Some test title",
            overview: "Some overview text",
            hide_chapter_navigation: true,
            in_beta: true,
          )
          visit edition_path(published_guide_edition)

          assert page.has_css?("h3", text: "Title")
          assert page.has_css?("p", text: published_guide_edition.title)

          assert page.has_css?("h3", text: "Meta tag description")
          assert page.has_css?("p", text: published_guide_edition.overview)

          assert page.has_css?(".govuk-heading-m", text: "Chapters")

          assert_not page.has_css?(".govuk-button", text: "Add new chapter")

          assert page.has_css?("h3", text: "Is every chapter part of a step by step?")

          assert page.has_css?("h3", text: "Is this beta content?")

          assert page.has_css?("p", text: "Yes", count: 2)
        end

        should "show guide chapter list for guide edition if present" do
          published_guide_edition_with_parts = FactoryBot.create(
            :guide_edition_with_two_parts,
            state: "published",
            title: "Some test title",
            overview: "Some overview text",
            hide_chapter_navigation: true,
            in_beta: true,
          )
          visit edition_path(published_guide_edition_with_parts)

          assert page.has_css?("h3", text: "Title")
          assert page.has_css?("p", text: published_guide_edition_with_parts.title)

          assert page.has_css?("h3", text: "Meta tag description")
          assert page.has_css?("p", text: published_guide_edition_with_parts.overview)

          assert page.has_css?(".govuk-heading-m", text: "Chapters")

          assert page.has_css?(".govuk-summary-list__row", text: "PART !")
          assert page.has_css?(".govuk-summary-list__row", text: "PART !!")
          assert page.has_css?(".govuk-summary-list__actions", text: "View", minimum: 2)

          assert_not page.has_css?(".govuk-button", text: "Add new chapter")

          assert page.has_css?("h3", text: "Is every chapter part of a step by step?")

          assert page.has_css?("h3", text: "Is this beta content?")

          assert page.has_css?("p", text: "Yes", count: 2)
        end

        should "show View chapter page when View chapter link is clicked" do
          published_guide_edition_with_parts = FactoryBot.create(
            :guide_edition_with_two_parts,
            state: "published",
            title: "Some test title",
            overview: "Some overview text",
            hide_chapter_navigation: true,
            in_beta: true,
          )
          visit edition_path(published_guide_edition_with_parts)

          within all(".govuk-summary-list__row").last do
            click_link("View")
          end
          assert page.has_content?("View chapter")

          assert page.has_css?("h3", text: "Title")
          assert page.has_css?("p", text: "PART !!")

          assert page.has_css?("h3", text: "Slug")
          assert page.has_css?("p", text: "part-two")

          assert page.has_css?("h3", text: "Body")
          assert page.has_css?("p", text: "This is some more version text.")
        end

        should "show 'None added' for empty fields in guide edition" do
          [nil, ""].each do |empty_value|
            empty_guide_edition = FactoryBot.create(
              :guide_edition,
              state: "published",
              title: "Edit page title",
              overview: empty_value,
              hide_chapter_navigation: true,
              in_beta: true,
            )
            visit edition_path(empty_guide_edition)

            assert page.has_css?("p", text: "None added", count: 2)
          end
        end
      end

      context "transaction edition" do
        should "show fields for transaction edition" do
          visit_transaction_edition(state: "published", in_beta: true)

          assert page.has_css?("h3", text: "Title")
          assert page.has_css?("p", text: @transaction_edition.title)

          assert page.has_css?("h3", text: "Meta tag description")
          assert page.has_css?("p", text: @transaction_edition.overview)

          assert page.has_css?("h3", text: "Introduction")
          assert page.has_css?("p", text: @transaction_edition.introduction)

          assert page.has_css?("h3", text: "Start button text")
          assert page.has_css?("p", text: @transaction_edition.start_button_text)

          assert page.has_css?("h3", text: "Text below the start button (optional)")
          assert page.has_css?("p", text: @transaction_edition.will_continue_on)

          assert page.has_css?("h3", text: "Link to start of transaction")
          assert page.has_css?("p", text: @transaction_edition.link)

          assert page.has_css?("h3", text: "More information (optional)")
          assert page.has_css?("p", text: @transaction_edition.more_information)

          assert page.has_css?("h3", text: "Other ways to apply (optional)")
          assert page.has_css?("p", text: @transaction_edition.alternate_methods)

          assert page.has_css?("h3", text: "What you need to know (optional)")
          assert page.has_css?("p", text: @transaction_edition.need_to_know)

          assert page.has_css?("h3", text: "Is this beta content?")
          assert page.has_css?("p", text: "Yes")

          assert page.has_css?("h3", text: "Public change note")
          assert page.has_css?("p", text: "None added")

          @transaction_edition.in_beta = false
          @transaction_edition.save!(validate: false)
          visit edition_path(@transaction_edition)
          assert page.has_css?("p", text: "No")
        end

        should "show 'None added' for empty fields in transaction edition" do
          [nil, ""].each do |empty_value|
            empty_transaction_edition = FactoryBot.create(
              :transaction_edition,
              title: "Edit page title",
              state: "published",
              overview: empty_value,
              in_beta: true,
              introduction: empty_value,
              more_information: empty_value,
              need_to_know: empty_value,
              link: empty_value,
              will_continue_on: empty_value,
              alternate_methods: empty_value,
            )
            visit edition_path(empty_transaction_edition)

            assert page.has_css?("p", text: "None added", count: 8)
          end
        end
      end

      context "completed transaction edition" do
        should "show fields for completed transaction edition with no promotion" do
          visit_completed_transaction_edition(state: "published", in_beta: true)

          assert page.has_css?("h3", text: "Title")
          assert page.has_css?("p", text: @completed_transaction_edition.title)

          assert page.has_css?("h3", text: "Meta tag description")
          assert page.has_css?("p", text: @completed_transaction_edition.overview)

          assert page.has_css?("h3", text: "Promotion")
          assert page.has_css?("p", text: "None added", count: 2)

          assert page.has_css?("h3", text: "Is this beta content?")
          assert page.has_css?("p", text: "Yes")

          assert page.has_css?("h3", text: "Public change note")

          @completed_transaction_edition.in_beta = false
          @completed_transaction_edition.save!(validate: false)
          visit edition_path(@completed_transaction_edition)
          assert page.has_css?("p", text: "No")
        end

        should "show fields for completed transaction edition with organ donation promotion" do
          visit_completed_transaction_edition(
            state: "published",
            choice: "organ_donor",
            url: "https://example.com",
            opt_in_url: "https://opt-in.com",
            opt_out_url: "https://opt-out.com",
          )

          assert page.has_css?("h3", text: "Promotion")
          assert page.has_css?("p", text: "Organ donation")

          assert page.has_css?("h3", text: "Promotion URL")
          assert page.has_css?("p", text: "https://example.com")

          assert page.has_css?("h3", text: "Opt-in URL")
          assert page.has_css?("p", text: "https://opt-in.com")

          assert page.has_css?("h3", text: "Opt-out URL")
          assert page.has_css?("p", text: "https://opt-out.com")
        end

        should "show fields for completed transaction edition with photo id promotion" do
          visit_completed_transaction_edition(
            state: "published",
            choice: "bring_id_to_vote",
            url: "https://example.com",
          )

          assert page.has_css?("h3", text: "Promotion")
          assert page.has_css?("p", text: "Bring photo ID to vote")

          assert page.has_css?("h3", text: "Promotion URL")
          assert page.has_css?("p", text: "https://example.com")
        end

        should "show fields for completed transaction edition with mot reminder promotion" do
          visit_completed_transaction_edition(
            state: "published",
            choice: "mot_reminder",
            url: "https://example.com",
          )

          assert page.has_css?("h3", text: "Promotion")
          assert page.has_css?("p", text: "MOT reminders")

          assert page.has_css?("h3", text: "Promotion URL")
          assert page.has_css?("p", text: "https://example.com")
        end

        should "show fields for completed transaction edition with electric vehicle promotion" do
          visit_completed_transaction_edition(
            state: "published",
            choice: "electric_vehicle",
            url: "https://example.com",
          )

          assert page.has_css?("h3", text: "Promotion")
          assert page.has_css?("p", text: "Electric vehicles")

          assert page.has_css?("h3", text: "Promotion URL")
          assert page.has_css?("p", text: "https://example.com")
        end

        should "show 'None added' for empty fields in completed transaction edition" do
          [nil, ""].each do |empty_value|
            empty_completed_transaction_edition = FactoryBot.create(
              :completed_transaction_edition,
              title: "Edit page title",
              overview: empty_value,
              state: "published",
              presentation_toggles: { promotion_choice: { choice: "none" } },
              in_beta: true,
            )

            visit edition_path(empty_completed_transaction_edition)

            assert page.has_css?("p", text: "None added", count: 3)
          end
        end
      end

      context "user is a govuk_editor" do
        should "show a 'create new edition' button when there isn't an existing draft edition" do
          published_edition = FactoryBot.create(
            :edition,
            state: "published",
          )
          visit edition_path(published_edition)

          assert page.has_button?("Create new edition")
          assert page.has_no_link?("Edit latest edition")
        end

        should "show an 'edit latest edition' link when there is an existing draft edition" do
          published_edition = FactoryBot.create(
            :edition,
            state: "published",
          )
          FactoryBot.create(:edition, panopticon_id: published_edition.artefact.id, state: "draft")
          visit edition_path(published_edition)

          assert page.has_no_button?("Create new edition")
          assert page.has_link?("Edit latest edition")
        end
      end

      context "user is a welsh_editor" do
        setup do
          login_as_welsh_editor
        end

        context "viewing a welsh edition" do
          setup do
            @welsh_published_edition = FactoryBot.create(
              :edition,
              :welsh,
              state: "published",
            )
          end

          should "show a 'create new edition' button when there isn't an existing draft edition" do
            visit edition_path(@welsh_published_edition)

            assert page.has_button?("Create new edition")
            assert page.has_no_link?("Edit latest edition")
          end

          should "show an 'edit latest edition' link when there is an existing draft edition" do
            FactoryBot.create(:edition, panopticon_id: @welsh_published_edition.artefact.id, state: "draft")
            visit edition_path(@welsh_published_edition)

            assert page.has_no_button?("Create new edition")
            assert page.has_link?("Edit latest edition")
          end
        end

        context "viewing a non-welsh edition" do
          setup do
            @non_welsh_published_edition = FactoryBot.create(
              :edition,
              state: "published",
            )
          end

          should "not show a 'create new edition' button when there isn't an existing draft edition" do
            visit edition_path(@non_welsh_published_edition)

            assert page.has_no_button?("Create new edition")
            assert page.has_no_link?("Edit latest edition")
          end

          should "not show an 'edit latest edition' link when there is an existing draft edition" do
            FactoryBot.create(:edition, panopticon_id: @non_welsh_published_edition.artefact.id, state: "draft")
            visit edition_path(@non_welsh_published_edition)

            assert page.has_no_button?("Create new edition")
            assert page.has_no_link?("Edit latest edition")
          end
        end
      end

      context "user does not have editor permissions" do
        setup do
          login_as(FactoryBot.create(:user, name: "Non Editor"))
          @published_edition = FactoryBot.create(
            :edition,
            state: "published",
          )
        end

        should "not show a 'create new edition' button when there isn't an existing draft edition" do
          visit edition_path(@published_edition)

          assert page.has_no_button?("Create new edition")
          assert page.has_no_link?("Edit latest edition")
        end

        should "not show an 'edit latest edition' link when there is an existing draft edition" do
          FactoryBot.create(:edition, panopticon_id: @published_edition.artefact.id, state: "draft")
          visit edition_path(@published_edition)

          assert page.has_no_button?("Create new edition")
          assert page.has_no_link?("Edit latest edition")
        end
      end

      should "show a 'view on GOV.UK' link" do
        published_edition = FactoryBot.create(
          :edition,
          state: "published",
          slug: "a-test-slug",
        )
        visit edition_path(published_edition)

        assert page.has_link?("View on GOV.UK (opens in new tab)", href: "#{Plek.website_root}/#{published_edition.slug}")
      end
    end

    context "archived edition" do
      should "show a message when all editions are unpublished" do
        published_edition = FactoryBot.create(
          :answer_edition,
          title: "A published edition",
          panopticon_id: FactoryBot.create(
            :artefact,
          ).id,
          state: "published",
        )

        new_edition = FactoryBot.create(
          :answer_edition,
          title: "A new edition of a published edition",
          panopticon_id: published_edition.artefact.id,
          state: "draft",
        )

        new_edition.artefact.state = "archived"
        new_edition.artefact.save!
        visit edition_path(new_edition)

        assert page.has_text?("This content has been unpublished and is no longer available on the website. All editions have been archived.")
      end

      should "not show the sidebar" do
        archived_edition = FactoryBot.create(
          :edition,
          state: "archived",
        )
        visit edition_path(archived_edition)

        assert page.has_no_css?(".sidebar-components")
      end

      should "show common content-type fields" do
        archived_edition = FactoryBot.create(
          :edition,
          state: "archived",
          title: "Some test title",
          overview: "Some overview text",
          in_beta: true,
        )
        visit edition_path(archived_edition)

        assert page.has_css?("h3", text: "Title")
        assert page.has_css?("p", text: archived_edition.title)
        assert page.has_css?("h3", text: "Meta tag description")
        assert page.has_css?("p", text: archived_edition.overview)
        assert page.has_css?("h3", text: "Is this beta content?")
        assert page.has_css?("p", text: "Yes")

        archived_edition.in_beta = false
        archived_edition.save!(validate: false)
        visit edition_path(archived_edition)
        assert page.has_css?("p", text: "No")
      end

      should "show body field" do
        archived_edition = FactoryBot.create(
          :answer_edition,
          state: "archived",
          body: "## Some body text",
        )
        visit edition_path(archived_edition)

        assert page.has_css?("h3", text: "Body")
        assert page.has_css?("div", text: archived_edition.body)
      end

      should "show public change field" do
        archived_edition = FactoryBot.create(
          :answer_edition,
          state: "archived",
          in_beta: true,
          major_change: false,
        )
        visit edition_path(archived_edition)

        assert page.has_css?("h3", text: "Public change note")
        assert page.has_css?("p", text: "None added")

        archived_edition.major_change = true
        archived_edition.change_note = "Change note for test"
        archived_edition.save!(validate: false)
        visit edition_path(archived_edition)

        assert page.has_text?(archived_edition.change_note)
      end
    end

    context "Fact check edition" do
      %i[draft in_review amends_needed fact_check_received ready scheduled_for_publishing published archived].each do |state|
        context "when state is '#{state}'" do
          setup do
            send "visit_#{state}_edition"
          end

          should "not show the 'Resend fact check email' link and text" do
            assert page.has_no_link?("Resend fact check email")
            assert page.has_no_text?("You've requested this edition to be fact checked. We're awaiting a response.")
          end
        end
      end

      context "when state is 'Fact check" do
        should "not show the link or text to non-editors" do
          login_as(FactoryBot.create(:user, name: "Stub User"))
          visit_fact_check_edition

          assert page.has_no_link?("Resend fact check email")
          assert page.has_no_text?("You've requested this edition to be fact checked. We're awaiting a response.")
        end

        should "not show the link or text to welsh editors viewing a non-welsh edition" do
          login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
          visit_fact_check_edition

          assert page.has_no_link?("Resend fact check email")
          assert page.has_no_text?("You've requested this edition to be fact checked. We're awaiting a response.")
        end

        should "show the 'Resend fact check email' link and text to govuk editors" do
          login_as(@govuk_editor)
          visit_fact_check_edition

          assert page.has_link?("Resend fact check email")
          assert page.has_text?("You've requested this edition to be fact checked. We're awaiting a response.")
        end

        should "show the requester specific text to govuk editors" do
          login_as(@govuk_editor)
          create_fact_check_edition(@govuk_requester)
          visit edition_path(@fact_check_edition)

          assert page.has_text?("Stub requester requested this edition to be fact checked. We're awaiting a response.")
        end

        should "show Preview link" do
          visit_fact_check_edition
          assert page.has_link?("Preview (opens in new tab)")
        end

        context "user does not have editor permissions" do
          setup do
            login_as(FactoryBot.create(:user, name: "Non Editor"))
            visit_fact_check_edition
          end

          should "not show any editable components" do
            assert page.has_no_css?(".govuk-textarea")
            assert page.has_no_css?(".govuk-input")
            assert page.has_no_css?(".govuk-radios")
          end

          should "not show the Save button" do
            assert page.has_no_button?("Save")
          end

          should "show the Preview link" do
            assert page.has_link?("Preview (opens in new tab)")
          end
        end
      end

      context "when state is 'Fact check received'" do
        context "when user has govuk editor permissions" do
          setup do
            login_as(FactoryBot.create(:user, :govuk_editor))
            visit_fact_check_received_edition
          end

          should "show Preview link" do
            assert page.has_link?("Preview (opens in new tab)")
          end

          should "show the fact check inset text" do
            assert page.has_text?("We have received a fact check response for this edition.")
            assert page.has_text?("Please check the response in History and notes and select an action below.")
          end

          context "user does not have editor permissions" do
            setup do
              login_as(FactoryBot.create(:user, name: "Non Editor"))
              visit_fact_check_received_edition
            end

            should "not show any editable components" do
              assert page.has_no_css?(".govuk-textarea")
              assert page.has_no_css?(".govuk-input")
              assert page.has_no_css?(".govuk-radios")
            end

            should "not show the Save button" do
              assert page.has_no_button?("Save")
            end

            should "not show the fact check inset text" do
              assert page.has_no_text?("We have received a fact check response for this edition./nPlease check the response in History & Notes, and select an action below.")
            end

            should "show the Preview link" do
              assert page.has_link?("Preview (opens in new tab)")
            end
          end

          should "navigate to the 'Resend fact check email' page when the link is clicked" do
            login_as(@govuk_editor)
            visit_fact_check_edition

            click_link("Resend fact check email")

            assert_current_path resend_fact_check_email_page_edition_path(@fact_check_edition.id)
          end
        end
      end

      context "Request amendments link" do
        context "edition is not in review" do
          should "not show the link for a draft edition" do
            visit_draft_edition
            assert page.has_no_link?("Request amendments")
          end
        end

        context "edition is in review" do
          should "not show the link to non-editors" do
            login_as(FactoryBot.create(:user, name: "Stub User"))
            visit_in_review_edition
            assert page.has_no_link?("Request amendments")
          end

          should "not show the link to welsh editors viewing a non-welsh edition" do
            login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
            visit_in_review_edition

            assert page.has_no_link?("Request amendments")
          end

          should "not show the link to the requester" do
            login_as(@govuk_requester)
            visit_in_review_edition
            assert page.has_no_link?("Request amendments")
          end

          should "show the link to editors who are not the requester" do
            login_as(@govuk_editor)
            visit_in_review_edition
            assert page.has_link?("Request amendments")
          end

          should "navigate to the 'Request amendments' page when the link is clicked" do
            login_as(@govuk_editor)
            visit_in_review_edition

            click_link("Request amendments")

            assert_current_path request_amendments_page_edition_path(@in_review_edition.id)
          end
        end

        context "edition is ready" do
          should "not show the link to non-editors" do
            login_as(FactoryBot.create(:user, name: "Stub User"))
            visit_ready_edition
            assert page.has_no_link?("Request amendments")
          end

          should "not show the link to welsh editors viewing a non-welsh edition" do
            login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
            visit_ready_edition
            assert page.has_no_link?("Request amendments")
          end

          should "show the link to editors" do
            login_as(@govuk_editor)
            visit_ready_edition
            assert page.has_link?("Request amendments")
          end

          should "navigate to the 'Request amendments' page when the link is clicked" do
            login_as(@govuk_editor)
            visit_ready_edition
            click_link("Request amendments")

            assert_current_path request_amendments_page_edition_path(@ready_edition.id)
          end
        end

        context "edition is out for fact check" do
          should "not show the link to non editors" do
            login_as(FactoryBot.create(:user, name: "Stub User"))
            visit_fact_check_edition

            assert page.has_no_link?("Request amendments")
          end

          should "not show the link to welsh editors viewing a non-welsh edition" do
            login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
            visit_fact_check_edition

            assert page.has_no_link?("Request amendments")
          end

          should "show the link to editors" do
            login_as(@govuk_editor)
            visit_fact_check_edition

            assert page.has_link?("Request amendments")
          end

          should "show the link to welsh editors viewing a welsh edition" do
            login_as_welsh_editor
            welsh_edition = FactoryBot.create(:edition, :welsh, state: "ready")
            visit edition_path(welsh_edition)

            assert page.has_link?("Request amendments")
          end

          should "navigate to the 'Request amendments' page when the link is clicked" do
            login_as(@govuk_editor)
            visit_fact_check_edition
            click_link("Request amendments")

            assert_current_path request_amendments_page_edition_path(@fact_check_edition.id)
          end
        end

        context "edition is fact check received" do
          should "not show the link to non editors" do
            login_as(FactoryBot.create(:user, name: "Stub User"))
            visit_fact_check_received_edition

            assert page.has_no_link?("Request amendments")
          end

          should "not show the link to welsh editors viewing a non-welsh edition" do
            login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
            visit_fact_check_received_edition

            assert page.has_no_link?("Request amendments")
          end

          should "show the link to editors" do
            login_as(@govuk_editor)
            visit_fact_check_received_edition

            assert page.has_link?("Request amendments")
          end

          should "show the link to welsh editors viewing a welsh edition" do
            login_as_welsh_editor
            welsh_edition = FactoryBot.create(:edition, :welsh, :fact_check_received)
            visit edition_path(welsh_edition)

            assert page.has_link?("Request amendments")
          end

          should "navigate to the 'Request amendments' page when the link is clicked" do
            login_as(@govuk_editor)
            visit_fact_check_received_edition
            click_link("Request amendments")

            assert_current_path request_amendments_page_edition_path(@fact_check_received_edition.id)
          end
        end
      end

      context "No changes needed link (fact_check_received state)" do
        context "edition is fact check received" do
          should "not show the link to non editors" do
            login_as(FactoryBot.create(:user, name: "Stub User"))
            visit_fact_check_received_edition

            assert page.has_no_link?("No changes needed")
          end

          should "not show the link to welsh editors viewing a non-welsh edition" do
            login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
            visit_fact_check_received_edition

            assert page.has_no_link?("No changes needed")
          end

          should "show the link to editors" do
            login_as(@govuk_editor)
            visit_fact_check_received_edition

            assert page.has_link?("No changes needed")
          end

          should "show the link to welsh editors viewing a welsh edition" do
            login_as_welsh_editor
            welsh_edition = FactoryBot.create(:edition, :welsh, :fact_check_received)
            visit edition_path(welsh_edition)

            assert page.has_link?("No changes needed")
          end

          should "navigate to the 'Approve fact check' page when the link is clicked" do
            login_as(@govuk_editor)
            visit_fact_check_received_edition
            click_link("No changes needed")

            assert_current_path approve_fact_check_page_edition_path(@fact_check_received_edition.id)
          end
        end
      end

      context "No changes needed link (in_review state)" do
        context "edition is not in review" do
          should "not show the link" do
            visit_draft_edition
            assert page.has_no_link?("No changes needed")
          end
        end

        context "edition is in review" do
          should "not show the link to non-editors" do
            login_as(FactoryBot.create(:user, name: "Stub User"))
            visit_in_review_edition
            assert page.has_no_link?("No changes needed")
          end

          should "not show the link to welsh editors viewing a non-welsh edition" do
            login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
            visit_in_review_edition

            assert page.has_no_link?("No changes needed")
          end

          should "not show the link to the requester" do
            login_as(@govuk_requester)
            visit_in_review_edition
            assert page.has_no_link?("No changes needed")
          end

          should "show the link to editors who are not the requester" do
            login_as(@govuk_editor)
            visit_in_review_edition
            assert page.has_link?("No changes needed")
          end

          should "navigate to the 'No changes needed' page when the link is clicked" do
            login_as(@govuk_editor)
            visit_in_review_edition

            click_link("No changes needed")

            assert_current_path no_changes_needed_page_edition_path(@in_review_edition.id)
          end
        end
      end

      context "Skip review link" do
        context "viewing an 'in review' edition as the review requester" do
          setup do
            @edition = FactoryBot.create(:edition, state: "in_review", review_requested_at: 1.hour.ago)
            @requester = FactoryBot.create(:user)
            @edition.actions.create!(
              request_type: Action::REQUEST_AMENDMENTS,
              requester_id: @requester.id,
            )
            login_as(@requester)
          end

          should "show the 'Skip review' link when the user has the 'skip_review' permission" do
            @requester.permissions << "skip_review"

            visit edition_path(@edition)

            assert page.has_link?("Skip review")
          end

          should "navigate to 'Skip review' page when 'Skip review' link is clicked" do
            @requester.permissions << "skip_review"
            visit edition_path(@edition)

            click_link("Skip review")

            assert_current_path skip_review_page_edition_path(@edition.id)
          end

          should "not show the 'Skip review' link when the user does not have the 'skip_review' permission" do
            visit edition_path(@edition)

            assert page.has_no_link?("Skip review")
          end
        end

        context "viewing an 'in review' edition as somebody other than the review requester" do
          setup do
            @edition = FactoryBot.create(:edition, state: "in_review", review_requested_at: 1.hour.ago)
            @edition.actions.create!(
              request_type: Action::REQUEST_AMENDMENTS,
              requester_id: FactoryBot.create(:user).id,
            )
            @user = FactoryBot.create(:user, :skip_review)
            login_as(@user)
          end

          should "not show the 'Skip review' link" do
            visit edition_path(@edition)

            assert page.has_no_link?("Skip review")
          end
        end

        should "not show the 'Skip review' link when viewing an edition that is not 'in review'" do
          edition = FactoryBot.create(:edition, state: "draft")
          @user = FactoryBot.create(:user, :skip_review)
          login_as(@user)

          visit edition_path(edition)

          assert page.has_no_link?("Skip review")
        end
      end

      context "edit assignee link" do
        context "user does not have required permissions" do
          setup do
            login_as(FactoryBot.create(:user, name: "Stub User"))
            visit_draft_edition
          end

          should "not show 'Edit' link when user is not govuk editor or welsh editor" do
            within :css, ".editions__edit__summary" do
              within all(".govuk-summary-list__row")[0] do
                assert page.has_no_link?("Edit")
              end
            end
          end

          should "not show 'Edit' link when user is welsh editor and edition is not welsh" do
            login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
            visit_draft_edition

            within :css, ".editions__edit__summary" do
              within all(".govuk-summary-list__row")[0] do
                assert page.has_no_link?("Edit")
              end
            end
          end
        end

        context "user has required permissions" do
          %i[published archived scheduled_for_publishing].each do |state|
            context "when state is '#{state}'" do
              setup do
                send "visit_#{state}_edition"
              end

              should "not show 'Edit' link" do
                within :css, ".editions__edit__summary" do
                  within all(".govuk-summary-list__row")[0] do
                    assert page.has_no_link?("Edit")
                  end
                end
              end
            end
          end

          %i[draft amends_needed in_review fact_check_received fact_check ready].each do |state|
            context "when state is '#{state}'" do
              setup do
                send "visit_#{state}_edition"
                click_link("Admin")
              end

              should "show 'Edit' link" do
                within :css, ".editions__edit__summary" do
                  within all(".govuk-summary-list__row")[0] do
                    assert page.has_link?("Edit")
                  end
                end
              end

              should "navigate to edit assignee page when 'Edit' assignee is clicked" do
                within :css, ".editions__edit__summary" do
                  within all(".govuk-summary-list__row")[0] do
                    click_link("Edit")
                  end
                end

                assert(page.current_path.include?("/edit_assignee"))
              end
            end
          end

          context "edit assignee page" do
            setup do
              visit_draft_edition
              within :css, ".editions__edit__summary" do
                within all(".govuk-summary-list__row")[0] do
                  click_link("Edit")
                end
              end
            end

            should "show title and page title" do
              assert page.has_title?("Assign person")
              assert page.has_text?(@draft_edition.title)
            end

            should "show only enabled users as radio button options" do
              FactoryBot.create(:user, name: "Disabled User", disabled: true)
              all_enabled_users_names = []
              User.enabled.each { |user| all_enabled_users_names << user.name }
              all_user_radio_buttons = find_all(".govuk-radios__item").map(&:text)

              assert all_user_radio_buttons.exclude?("Disabled User")

              all_enabled_users_names.each do |users|
                assert all_user_radio_buttons.include?(users)
              end
            end

            should "allow currently assigned user to be unassigned" do
              user = FactoryBot.create(:user, :govuk_editor)
              @govuk_editor.assign(@draft_edition, user)
              visit current_path

              choose "None"
              click_on "Save"

              assert_equal(page.current_path, "/editions/#{@draft_edition.id}")
            end

            should "navigate to editions edit page when 'Cancel' link is clicked" do
              click_link("Cancel")

              assert_equal(page.current_path, "/editions/#{@draft_edition.id}")
            end
          end
        end
      end

      context "edit 2i reviewer link" do
        context "user does not have required permissions" do
          setup do
            login_as(FactoryBot.create(:user, name: "Stub User"))
            visit_in_review_edition
          end

          should "not show 'Edit' link when user is not govuk editor or welsh editor" do
            within :css, ".editions__edit__summary" do
              within all(".govuk-summary-list__row")[3] do
                assert page.has_no_link?("Edit")
              end
            end
          end

          should "not show 'Edit' link when user is welsh editor and edition is not welsh" do
            login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
            visit_in_review_edition

            within :css, ".editions__edit__summary" do
              within all(".govuk-summary-list__row")[3] do
                assert page.has_no_link?("Edit")
              end
            end
          end
        end

        context "user has required permissions" do
          should "show 'Edit' link" do
            visit_in_review_edition

            within :css, ".editions__edit__summary" do
              within all(".govuk-summary-list__row")[3] do
                assert page.has_link?("Edit")
              end
            end
          end

          should "navigate to edit 2i reviewer page when 'Edit' link is clicked" do
            visit_in_review_edition

            within :css, ".editions__edit__summary" do
              within all(".govuk-summary-list__row")[3] do
                click_link("Edit")
              end
            end

            assert(page.current_path.include?("/edit_reviewer"))
          end

          context "edit reviewer page" do
            setup do
              @edition = FactoryBot.create(:answer_edition, state: "in_review", title: "An edition with a reviewer assigned", review_requested_at: 1.hour.ago, reviewer: @govuk_editor.id)
              @edition.actions.create!(
                request_type: Action::REQUEST_AMENDMENTS,
                requester_id: @govuk_requester.id,
              )

              visit edit_reviewer_edition_path(@edition)
            end

            should "show title and page title" do
              assert page.has_title?("Assign 2i reviewer")
              assert page.has_text?(@edition.title)
            end

            should "navigate to editions edit page when 'Cancel' link is clicked" do
              click_link("Cancel")

              assert_equal(page.current_path, "/editions/#{@edition.id}")
            end

            context "radio buttons" do
              setup do
                FactoryBot.create(:user, name: "Disabled User", disabled: true)
                @all_enabled_users_names = []
                User.enabled.each { |user| @all_enabled_users_names << user.name }
                @all_user_radio_buttons = find_all(".govuk-radios__item").map(&:text)
              end

              should "show only enabled users as radio button options" do
                assert @all_user_radio_buttons.exclude?("Disabled User")

                @all_enabled_users_names.each do |users|
                  assert @all_user_radio_buttons.include?(users)
                end
              end

              should "show the currently assigned reviewer as the first radio button option and 'none' as the second" do
                within all(".govuk-radios__item")[0] do
                  assert page.has_css?("input[value='#{@govuk_editor.id}']")
                end

                within all(".govuk-radios__item")[1] do
                  assert page.has_css?("input[value='none']")
                end
              end

              should "not show a 'none' option when there is no assigned reviewer" do
                @edition_no_reviewer = FactoryBot.create(:answer_edition, state: "in_review", title: "An edition with no reviewer assigned", review_requested_at: 1.hour.ago, reviewer: nil)
                @edition_no_reviewer.actions.create!(
                  request_type: Action::REQUEST_AMENDMENTS,
                  requester_id: @govuk_requester.id,
                )

                visit edit_reviewer_edition_path(@edition_no_reviewer)

                within :css, ".govuk-radios" do
                  assert page.has_no_css?("input[value='none']")
                end
              end
            end
          end
        end
      end

      context "content block guidance" do
        context "when show_link_to_content_block_manager? is false" do
          setup do
            @test_strategy.switch!(:show_link_to_content_block_manager, false)
            visit_draft_edition
          end

          should "not show the content block guidance" do
            assert_not page.has_text?("Use Content Block Manager (opens in new tab) to create, edit and use standardised content across GOV.UK")
          end
        end

        context "when show_link_to_content_block_manager? is true" do
          setup do
            @test_strategy.switch!(:show_link_to_content_block_manager, true)
          end

          %w[draft ready published archived].each do |state|
            should "show the content block guidance with content in #{state} state" do
              visit_transaction_edition(state: state)
              assert page.has_text?("Use Content Block Manager (opens in new tab) to create, edit and use standardised content across GOV.UK")
            end

            should "not show the content block guidance when content type has no GOVSPEAK field in #{state} state" do
              visit_completed_transaction_edition(state: state)
              assert_not page.has_text?("Use Content Block Manager (opens in new tab) to create, edit and use standardised content across GOV.UK")
            end
          end
        end
      end

      context "'Publish' button" do
        should "show the 'Publish' button if user has govuk_editor permission" do
          login_as(@govuk_editor)
          visit_ready_edition

          assert page.has_link?("Publish", href: send_to_publish_page_edition_path(@ready_edition))
        end

        should "show the 'Publish' button for welsh edition if user has welsh_editor permission" do
          login_as_welsh_editor
          welsh_edition = FactoryBot.create(:edition, :welsh, state: "ready")
          visit edition_path(welsh_edition)
          assert @user.has_editor_permissions?(welsh_edition)

          assert page.has_link?("Publish", href: send_to_publish_page_edition_path(welsh_edition))
        end

        should "not show the 'Publish' button if the user does not have permissions" do
          login_as(FactoryBot.create(:user, name: "Stub User"))
          visit_ready_edition

          assert_not page.has_link?("Publish", href: send_to_publish_page_edition_path(@ready_edition))
        end
      end

      context "'Fact check' button" do
        %i[ready fact_check_received].each do |state|
          should "show the 'Fact check' button on '#{state}' if user has govuk_editor permission" do
            login_as(@govuk_editor)
            @edition = FactoryBot.create(:edition, title: "Edit page title", state: state.to_s)
            visit edition_path(@edition)

            assert page.has_link?("Fact check", href: send_to_fact_check_page_edition_path(@edition))
          end

          should "show the 'Fact check' button on '#{state}' for welsh edition if user has welsh_editor permission" do
            login_as_welsh_editor
            welsh_edition = FactoryBot.create(:edition, :welsh, state: state.to_s)
            visit edition_path(welsh_edition)
            assert @user.has_editor_permissions?(welsh_edition)

            assert page.has_link?("Fact check", href: send_to_fact_check_page_edition_path(welsh_edition))
          end

          should "not show the 'Fact check' button on '#{state}' if the user does not have permissions" do
            login_as(FactoryBot.create(:user, name: "Stub User"))
            @edition = FactoryBot.create(:edition, title: "Edit page title", state: state.to_s)
            visit edition_path(@edition)

            assert page.has_no_link?("Fact check", href: "#")
          end
        end
      end
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

      context "Document has no external links when page loads" do
        setup do
          visit_draft_edition
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
          visit_draft_edition
          @draft_edition.artefact.external_links = [ArtefactExternalLink.build({ title: "Link One", url: "https://gov.uk" })]
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
          visit_draft_edition
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
          visit_draft_edition
          @draft_edition.artefact.external_links = [ArtefactExternalLink.build({ title: "Link One", url: "https://gov.uk" })]
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
  end

  context "Resend fact check email page" do
    should "render the 'Resend fact check email' page" do
      create_fact_check_edition
      visit resend_fact_check_email_page_edition_path(@fact_check_edition)

      assert page.has_content?(@fact_check_edition.title)
      assert page.has_content?("Resend fact check email")
      assert page.has_content?("Email addresses")
      assert page.has_content?("fact-checker-one@example.com, fact-checker-two@example.com")
      assert page.has_content?("Customised message")
      assert page.has_content?("The customised message")
      assert page.has_button?("Resend fact check email")
      assert page.has_link?("Cancel")
    end
  end

  context "Request amendments page" do
    should "save comment to edition history" do
      create_in_review_edition

      visit request_amendments_page_edition_path(@in_review_edition)
      fill_in "Amendment details (optional)", with: "Please make these changes"
      click_on "Request amendments"

      click_on "History and notes"
      assert page.has_content?("Request amendments by")
      assert page.has_content?("Please make these changes")
    end

    should "show success message and redirect back to the edit tab on submit" do
      create_in_review_edition
      visit request_amendments_page_edition_path(@in_review_edition)
      click_on "Request amendments"

      assert_current_path edition_path(@in_review_edition.id)
      assert page.has_text?("Amendments requested")
    end

    context "current user is also the requester" do
      setup do
        login_as(@govuk_requester)
      end

      should "populate comment box with submitted comment when there is an error" do
        create_in_review_edition
        login_as(@in_review_edition.latest_status_action.requester)

        visit request_amendments_page_edition_path(@in_review_edition)
        fill_in "Amendment details (optional)", with: "Please make these changes"
        click_on "Request amendments"

        assert page.has_content?("Due to a service problem, the request could not be made")
        assert page.has_content?("Please make these changes")
      end
    end
  end

  context "No changes needed page" do
    should "save comment to edition history" do
      create_in_review_edition

      visit no_changes_needed_page_edition_path(@in_review_edition)
      fill_in "Comment (optional)", with: "Looks great"
      click_on "Approve 2i"

      click_on "History and notes"
      assert page.has_content?("Approve review by")
      assert page.has_content?("Looks great")
    end

    should "show success message and redirect back to the edit tab on submit" do
      create_in_review_edition
      visit no_changes_needed_page_edition_path(@in_review_edition)
      click_button "Approve 2i"

      assert_current_path edition_path(@in_review_edition.id)
      assert page.has_text?("2i approved")
    end

    context "current user is also the requester" do
      setup do
        login_as(@govuk_requester)
      end

      should "populate comment box with submitted comment when there is an error" do
        create_in_review_edition
        login_as(@in_review_edition.latest_status_action.requester)

        visit no_changes_needed_page_edition_path(@in_review_edition)
        fill_in "Comment (optional)", with: "Great job!"
        click_on "Approve 2i"

        assert page.has_content?("Due to a service problem, the request could not be made")
        assert page.has_content?("Great job!")
      end
    end
  end

  context "Approve fact check page" do
    should "save comment to edition history" do
      create_fact_check_received_edition

      visit approve_fact_check_page_edition_path(@fact_check_received_edition)
      fill_in "Comment (optional)", with: "Looks great"
      click_on "Approve fact check"

      click_on "History and notes"
      assert page.has_content?("Approve fact check by")
      assert page.has_content?("Looks great")
    end

    should "show success message and redirect back to the edit tab on submit" do
      create_fact_check_received_edition

      visit approve_fact_check_page_edition_path(@fact_check_received_edition)
      click_button "Approve fact check"

      assert_current_path edition_path(@fact_check_received_edition.id)
      assert page.has_text?("Fact check approved")
    end

    context "current user is also the requester" do
      setup do
        login_as(@govuk_requester)
      end

      should "populate comment box with submitted comment when there is an error" do
        create_fact_check_received_edition
        visit approve_fact_check_page_edition_path(@fact_check_received_edition)

        @fact_check_received_edition.state = "ready"
        @fact_check_received_edition.save!

        fill_in "Comment (optional)", with: "Great job!"
        click_on "Approve fact check"

        assert page.has_content?("Edition is not in a state where fact check can be approved")
        assert page.has_content?("Great job!")
      end
    end
  end

  context "Skip review page" do
    context "current user may skip review" do
      setup do
        login_as(@govuk_requester)
        @govuk_requester.permissions << "skip_review"
      end

      should "render the 'Skip review' page" do
        create_in_review_edition

        visit skip_review_page_edition_path(@in_review_edition)

        assert page.has_content?("Skip review")
        assert page.has_content?(@in_review_edition.title)
        assert page.has_content?("You should only skip review in exceptional circumstances")
        assert page.has_content?("Comment (optional)")
        assert page.has_button?("Skip review")
        assert page.has_link?("Cancel")
      end

      should "save comment to edition history" do
        create_in_review_edition

        visit skip_review_page_edition_path(@in_review_edition)
        fill_in "Comment (optional)", with: "Looks great"
        click_on "Skip review"

        click_on "History and notes"
        assert page.has_content?("Skip review by Stub requester")
        assert page.has_content?("Looks great")
      end

      should "show success message and redirect back to the edit tab on submit" do
        create_in_review_edition
        visit skip_review_page_edition_path(@in_review_edition)
        click_button "Skip review"

        assert_current_path edition_path(@in_review_edition.id)
        assert page.has_text?("2i review skipped")
      end
    end

    context "current user is not the requester" do
      setup do
        @govuk_editor.permissions << "skip_review"
      end

      should "populate comment box with submitted comment when there is an error" do
        create_in_review_edition

        visit skip_review_page_edition_path(@in_review_edition)
        fill_in "Comment (optional)", with: "No review required"
        click_on "Skip review"

        assert page.has_content?("Due to a service problem, the request could not be made")
        assert page.has_content?("No review required")
      end
    end
  end

  context "Send to 2i page" do
    setup do
      create_draft_edition
      visit send_to_2i_page_edition_path(@draft_edition)
    end

    should "render the 'Send to 2i' page" do
      within :css, ".gem-c-heading" do
        assert page.has_css?("h1", text: "Send to 2i")
        assert page.has_css?(".gem-c-heading__context", text: @draft_edition.title)
      end

      assert page.has_text?("Explain what changes you did or did not make and why. Include a link to the relevant Zendesk ticket and Jira card. If you’ve added a change note already, you do not need to add another one.")
      assert page.has_link?("Read guidance on writing good change notes (opens in new tab)", href: "https://gov-uk.atlassian.net/l/cp/dwn06raQ")

      within :css, ".gem-c-textarea" do
        assert page.has_css?("textarea")
      end

      assert page.has_button?("Send to 2i")
      assert page.has_link?("Cancel")
    end

    should "redirect to edit tab when Cancel button is pressed on Send to 2i page" do
      click_link("Cancel")

      assert_current_path edition_path(@draft_edition.id)
    end

    should "show success message and redirect back to the edit tab on submit" do
      click_button "Send to 2i"

      assert_current_path edition_path(@draft_edition.id)
      assert page.has_text?("Sent to 2i")
    end
  end

  context "in_review edition (sent to 2i)" do
    context "user has the required permissions" do
      context "current user is also the requester" do
        setup do
          login_as(@govuk_requester)
          visit_in_review_edition("request_review", @govuk_requester)
        end

        should "display Save button and preview link" do
          assert page.has_button?("Save"), "No save button present"
          assert page.has_link?("Preview (opens in new tab)"), "No preview link present"
        end

        should "indicate that the current user requested a review" do
          assert page.has_text?("You've sent this edition to be reviewed")
        end

        should "not show 'Send to 2i' link as edition already in 'in review' state" do
          visit_in_review_edition
          assert page.has_no_link?("Send to 2i")
        end
      end

      context "current user is not the requester" do
        setup do
          login_as(@govuk_editor)
          visit_in_review_edition("request_review", @govuk_requester)
        end

        should "display Save button and preview link" do
          assert page.has_button?("Save"), "No save button present"
          assert page.has_link?("Preview (opens in new tab)"), "No preview link present"
        end

        should "indicate which other user requested a review" do
          assert page.has_text?("Stub requester sent this edition to be reviewed")
        end
      end
    end

    context "user does not have editor permissions" do
      setup do
        login_as(FactoryBot.create(:user, name: "Non Editor"))
        visit_in_review_edition
      end

      should "not show any editable components" do
        assert page.has_no_css?(".govuk-textarea")
        assert page.has_no_css?(".govuk-input")
        assert page.has_no_css?(".govuk-radios")
      end

      should "not show the Save button" do
        assert page.has_no_button?("Save")
      end

      should "show the Preview link" do
        assert page.has_link?("Preview (opens in new tab)")
      end
    end
  end

  context "Send to Fact check page" do
    should "render the page" do
      create_ready_edition
      visit send_to_fact_check_page_edition_path(@ready_edition)

      assert page.has_text?(@ready_edition.title)
      assert page.has_text?("Send to fact check")
      assert page.has_text?("Email addresses")
      assert page.has_css?(".gem-c-hint", text: "You can enter multiple email addresses if you comma separate them as follows: fact-checker-one@example.com, fact-checker-two@example.com")
      assert page.has_text?("Customised message")
      assert page.has_text?("The GOV.UK Content Team made the changes because")
      assert page.has_button?("Send to fact check")
      assert page.has_link?("Cancel")
    end

    should "redirect to edit tab when Cancel button is pressed on Send to Fact check page" do
      create_ready_edition
      visit send_to_fact_check_page_edition_path(@ready_edition)

      click_link("Cancel")

      assert_current_path edition_path(@ready_edition.id)
    end

    should "redirect back to the edit tab on submit and show success message" do
      create_ready_edition
      visit send_to_fact_check_page_edition_path(@ready_edition)

      fill_in "Email addresses", with: "fact-checker-one@example.com"
      fill_in "Customised message", with: "Please check this"
      click_button "Send to fact check"

      assert_current_path edition_path(@ready_edition.id)
      assert page.has_text?("Sent to fact check")
    end

    should "redirect back to the edit tab and show success message when pre-filled customised message is used" do
      create_ready_edition
      visit send_to_fact_check_page_edition_path(@ready_edition)
      assert page.has_text?("The GOV.UK Content Team made the changes because")

      fill_in "Email addresses", with: "fact-checker-one@example.com"
      click_button "Send to fact check"

      assert_current_path edition_path(@ready_edition.id)
      assert page.has_text?("Sent to fact check")
    end

    should "display an error message if an email address is invalid" do
      create_ready_edition
      visit send_to_fact_check_page_edition_path(@ready_edition)

      fill_in "Email addresses", with: "fact-checker-one.com"
      fill_in "Customised message", with: "Please check this"
      click_button "Send to fact check"

      assert_current_path send_to_fact_check_edition_path(@ready_edition.id)
      assert page.has_text?("Enter email addresses and/or customised message")
    end

    should "display an error message if customised message is empty" do
      create_ready_edition
      visit send_to_fact_check_page_edition_path(@ready_edition)

      fill_in "Email addresses", with: "fact-checker-one@example.com"
      fill_in "Customised message", with: ""
      click_button "Send to fact check"

      assert_current_path send_to_fact_check_edition_path(@ready_edition.id)
      assert page.has_text?("Enter email addresses and/or customised message")
    end

    should "keep user inputs when there is an error" do
      create_ready_edition
      visit send_to_fact_check_page_edition_path(@ready_edition)

      fill_in "Email addresses", with: "fact-checker-one.com"
      fill_in "Customised message", with: "Please check this"
      click_button "Send to fact check"

      assert_current_path send_to_fact_check_edition_path(@ready_edition.id)
      assert page.has_text?("Enter email addresses and/or customised message")
      assert page.has_css?("input[value='fact-checker-one.com']")
      assert page.has_text?("Please check this")
    end
  end

  context "Send to publish page" do
    should "save comment to edition history" do
      create_scheduled_for_publishing_edition

      visit send_to_publish_page_edition_path(@scheduled_for_publishing_edition)
      fill_in "Comment (optional)", with: "Looks great"
      click_on "Send to publish"

      click_on "History and notes"
      assert page.has_content?("Publish by")
      assert page.has_content?("Looks great")
    end

    should "populate comment box with submitted comment when there is an error" do
      edition = create_draft_edition

      visit send_to_publish_page_edition_path(edition)
      fill_in "Comment (optional)", with: "Publish a go-go!"
      click_on "Send to publish"

      assert page.has_content?("Edition is not in a state where it can be published")
      assert page.has_content?("Publish a go-go")
    end

    should "show an error when the edition is not in a state that can be published from" do
      edition = create_draft_edition

      visit send_to_publish_page_edition_path(edition)
      click_on "Send to publish"

      assert page.has_content?("Edition is not in a state where it can be published")
    end
  end

  context "Cancel scheduled publishing page" do
    should "save comment to edition history" do
      create_scheduled_for_publishing_edition

      visit cancel_scheduled_publishing_page_edition_path(@scheduled_for_publishing_edition)
      fill_in "Comment (optional)", with: "Looks great"
      click_on "Cancel scheduled publishing"

      click_on "History and notes"
      assert page.has_content?("Cancel scheduled publishing by")
      assert page.has_content?("Looks great")
    end

    should "populate comment box with submitted comment when there is an error" do
      edition = create_draft_edition

      visit cancel_scheduled_publishing_page_edition_path(edition)
      fill_in "Comment (optional)", with: "Forget about it"
      click_on "Cancel scheduled publishing"

      assert page.has_content?("Edition is not in a state where scheduling can be cancelled")
      assert page.has_content?("Forget about it")
    end
  end

  context "Compare editions" do
    should "render the compare editions page" do
      published_edition = FactoryBot.create(
        :answer_edition,
        body: "Some text",
        state: "published",
      )
      draft_edition = FactoryBot.create(
        :answer_edition,
        panopticon_id: published_edition.panopticon_id,
        title: "My draft edition",
        body: "Some added text",
        state: "draft",
      )

      visit diff_edition_path(draft_edition)

      assert page.has_content?(draft_edition.title)
      assert page.has_content?("Compare edition 1 and 2")
      assert page.has_content?("Answer")
      assert page.has_content?("2 Draft")
      assert page.has_link?("Back to History and notes", href: history_edition_path(draft_edition))
      assert page.has_css?("li.ins", text: "Some added text")
    end
  end

private

  def create_draft_edition
    @draft_edition = FactoryBot.create(:edition, title: "Edit page title", state: "draft", overview: "metatags", in_beta: 1, body: "The body")
  end

  def visit_draft_edition
    create_draft_edition
    visit edition_path(@draft_edition)
  end

  def create_draft_place_edition
    @draft_place_edition = FactoryBot.create(:place_edition, title: "Edit page title", state: "draft", overview: "metatags", in_beta: 1, place_type: "The place type", introduction: "some intro", more_information: "some more info", need_to_know: "some need to know")
  end

  def create_draft_local_transaction_edition
    @local_service = FactoryBot.create(:local_service, lgsl_code: 9012, description: "Whatever", providing_tier: %w[district unitary county])
    scotland_availability = FactoryBot.build(:scotland_availability, authority_type: "devolved_administration_service", alternative_url: "https://www.google.com")
    wales_availability = FactoryBot.build(:wales_availability, authority_type: "unavailable")

    @draft_local_transcation_edition = FactoryBot.create(:local_transaction_edition, title: "Edit page title", state: "draft", in_beta: 1, lgsl_code: @local_service.lgsl_code,
                                                                                     panopticon_id: FactoryBot.create(:artefact).id, lgil_code: 23, cta_text: "Find your local council", introduction: "Test introduction", more_information: "some more info",
                                                                                     need_to_know: "some need to know", before_results: "before results", after_results: "after results", scotland_availability:, wales_availability:)
  end

  def create_draft_guide_edition
    @draft_guide_edition = FactoryBot.create(:guide_edition, title: "Edit page title", state: "draft", overview: "metatags", in_beta: 1, hide_chapter_navigation: 1)
  end

  def create_draft_guide_edition_with_parts(state: "draft")
    @draft_guide_edition_with_parts = FactoryBot.create(:guide_edition_with_two_parts, title: "Edit page title", state: state, overview: "metatags", in_beta: 1, hide_chapter_navigation: 1, panopticon_id: FactoryBot.create(:artefact).id, publish_at: Time.zone.now + 1.hour)
  end

  def visit_draft_place_edition
    create_draft_place_edition
    visit edition_path(@draft_place_edition)
  end

  def visit_draft_local_transaction_edition
    create_draft_local_transaction_edition
    visit edition_path(@draft_local_transcation_edition)
  end

  def visit_draft_guide_edition
    create_draft_guide_edition
    visit edition_path(@draft_guide_edition)
  end

  def visit_draft_guide_edition_with_parts(state: "draft")
    create_draft_guide_edition_with_parts(state: state)
    visit edition_path(@draft_guide_edition_with_parts)
  end

  def create_completed_transaction_edition(state: "draft", in_beta: true, choice: "", url: "", opt_in_url: "", opt_out_url: "")
    @completed_transaction_edition = FactoryBot.create(
      :completed_transaction_edition,
      title: "Edit page title",
      overview: "metatags",
      state: state,
      body: "completed transaction body",
      presentation_toggles: { promotion_choice: { choice: choice, url: url, opt_in_url: opt_in_url, opt_out_url: opt_out_url } },
      in_beta: in_beta,
      publish_at: state == "scheduled_for_publishing" ? Time.zone.now + 1.hour : nil,
    )
  end

  def visit_completed_transaction_edition(state: "draft", in_beta: true, choice: "none", url: "", opt_in_url: "", opt_out_url: "")
    create_completed_transaction_edition(state: state, in_beta: in_beta, choice: choice, url: url, opt_in_url: opt_in_url, opt_out_url: opt_out_url)
    visit edition_path(@completed_transaction_edition)
  end

  def create_transaction_edition(state: "draft", in_beta: true)
    @transaction_edition = FactoryBot.create(
      :transaction_edition,
      title: "Edit page title",
      state: state,
      overview: "metatags",
      in_beta: in_beta,
      introduction: "Transaction introduction",
      more_information: "Transaction more information",
      need_to_know: "Transaction need to",
      link: "https://continue.com",
      will_continue_on: "To be continued...",
      alternate_methods: "Method A or B",
      publish_at: state == "scheduled_for_publishing" ? Time.zone.now + 1.hour : nil,
    )
  end

  def visit_transaction_edition(state: "draft", in_beta: true)
    create_transaction_edition(state: state, in_beta: in_beta)
    visit edition_path(@transaction_edition)
  end

  def create_empty_edition(type)
    @empty_edition = FactoryBot.create(
      type,
      title: "Edit page title",
    )
  end

  def visit_empty_edition(type)
    create_empty_edition(type)
    visit edition_path(@empty_edition)
  end

  def visit_published_edition
    create_published_edition
    visit edition_path(@published_edition)
  end

  def create_fact_check_edition(requester = @govuk_editor)
    @fact_check_edition = FactoryBot.create(:edition, title: "Edit page title", state: "fact_check")

    FactoryBot.create(
      :action,
      requester: requester,
      request_type: Action::SEND_FACT_CHECK,
      edition: @fact_check_edition,
      email_addresses: "fact-checker-one@example.com, fact-checker-two@example.com",
      customised_message: "The customised message",
    )
  end

  def create_fact_check_received_edition(requester = @govuk_editor)
    @fact_check_received_edition = FactoryBot.create(:edition, :fact_check_received, title: "Edit page title")

    FactoryBot.create(
      :action,
      requester: requester,
      request_type: Action::SEND_FACT_CHECK,
      edition: @fact_check_received_edition,
      email_addresses: "fact-checker-one@example.com, fact-checker-two@example.com",
      customised_message: "The customised message",
    )
  end

  def visit_fact_check_edition
    create_fact_check_edition
    visit edition_path(@fact_check_edition)
  end

  def visit_scheduled_for_publishing_edition
    create_scheduled_for_publishing_edition
    visit edition_path(@scheduled_for_publishing_edition)
  end

  def create_scheduled_for_publishing_edition
    @scheduled_for_publishing_edition = FactoryBot.create(:edition, title: "Edit page title", state: "scheduled_for_publishing", publish_at: Time.zone.now + 1.hour)
  end

  def visit_archived_edition
    @archived_edition = FactoryBot.create(:edition, title: "Edit page title", state: "archived")
    visit edition_path(@archived_edition)
  end

  def visit_in_review_edition(action = Action::REQUEST_AMENDMENTS, requester = @govuk_requester)
    create_in_review_edition(action, requester)

    visit edition_path(@in_review_edition)
  end

  def create_in_review_edition(action = Action::REQUEST_AMENDMENTS, requester = @govuk_requester)
    @in_review_edition = FactoryBot.create(:edition, title: "Edit page title", state: "in_review", review_requested_at: 1.hour.ago)

    @in_review_edition.actions.create!(
      request_type: action,
      requester_id: requester.id,
    )
  end

  def visit_amends_needed_edition
    @amends_needed_edition = FactoryBot.create(:edition, title: "Edit page title", state: "amends_needed")
    visit edition_path(@amends_needed_edition)
  end

  def visit_fact_check_received_edition
    @fact_check_received_edition = FactoryBot.create(:edition, title: "Edit page title", state: "fact_check_received")
    visit edition_path(@fact_check_received_edition)
  end

  def create_ready_edition
    @ready_edition = FactoryBot.create(:answer_edition, title: "Ready edition", state: "ready")
  end

  def visit_ready_edition
    create_ready_edition
    visit edition_path(@ready_edition)
  end

  def visit_new_edition_of_published_edition
    create_published_edition
    new_edition = FactoryBot.create(
      :edition,
      panopticon_id: @published_edition.artefact.id,
      state: "draft",
      change_note: "The change note",
    )
    visit edition_path(new_edition)
  end

  def create_published_edition
    @published_edition = FactoryBot.create(
      :edition,
      title: "Edit page title",
      panopticon_id: FactoryBot.create(
        :artefact,
        slug: "can-i-get-a-driving-licence",
      ).id,
      state: "published",
      slug: "can-i-get-a-driving-licence",
    )
  end

  def visit_old_edition_of_published_edition
    published_edition = FactoryBot.create(
      :edition,
      panopticon_id: FactoryBot.create(
        :artefact,
        slug: "can-i-get-a-driving-licence",
      ).id,
      state: "published",
      sibling_in_progress: 2,
    )

    FactoryBot.create(
      :edition,
      panopticon_id: published_edition.artefact.id,
      state: "draft",
      version_number: 2,
      change_note: "The change note",
    )
    visit edition_path(published_edition)
  end

  def create_important_note_for_edition(edition, note_text)
    FactoryBot.create(
      :action,
      requester: @govuk_editor,
      request_type: Action::IMPORTANT_NOTE,
      edition: edition,
      comment: note_text,
    )
  end

  def create_content_update_event(updated_by_user_uid:)
    {
      "created_at" => "2024-08-07 11:26:00",
      "payload" => {
        "source_block" => {
          "updated_by_user_uid" => updated_by_user_uid,
          "content_id" => SecureRandom.uuid,
          "title" => "Some content",
          "document_type" => "content_block_email_address",
        },
      },
    }
  end
end
