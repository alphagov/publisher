require "integration_test_helper"

class EditionEditTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    login_as(@govuk_editor)
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_edit, true)
    stub_holidays_used_by_fact_check
    stub_linkables
  end

  context "edit page" do
    setup do
      visit_published_edition
    end

    should "show all the tabs when user has required permission and edition is published" do
      assert page.has_text?("Edit")
      assert page.has_text?("Tagging")
      assert page.has_text?("Metadata")
      assert page.has_text?("History and notes")
      assert page.has_text?("Admin")
      assert page.has_text?("Related external links")
      assert page.has_text?("Unpublish")
    end

    should "show document summary and title" do
      assert page.has_title?("Edit page title")

      row = find_all(".govuk-summary-list__row")
      assert row[0].has_content?("Assigned to")
      assert row[1].has_text?("Content type")
      assert row[1].has_text?("Answer")
      assert row[2].has_text?("Edition")
      assert row[2].has_text?("1")
      assert row[2].has_text?("Published")
    end

    should "indicate when an edition does not have an assignee" do
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
  end

  context "edit assignee page" do
    should "only show editors as available for assignment" do
      edition = FactoryBot.create(:answer_edition, state: "draft")
      non_editor_user = FactoryBot.create(:user, name: "Non Editor User")

      visit edit_assignee_edition_path(edition)

      assert_selector "label", text: @govuk_editor.name
      assert_no_selector "label", text: non_editor_user.name
    end
  end

  context "metadata tab" do
    context "when state is 'draft'" do
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

    context "when state is not 'draft'" do
      setup do
        visit_published_edition
        click_link("Metadata")
      end

      should "show un-editable current value for slug and language" do
        assert page.has_no_field?("artefact[slug]")
        assert page.has_no_field?("artefact[language]")

        assert page.has_text?("Slug")
        assert page.has_text?(/can-i-get-a-driving-licence/)
        assert page.has_text?("Language")
        assert page.has_text?(/English/)
      end
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
        context "content type is retired" do
          setup do
            visit_retired_edition_in_published
            click_link("Admin")
          end

          should "not show the 'Update content type' form" do
            assert page.has_no_text?("Update content type")
          end
        end

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

    context "edit assignee link" do
      context "user does not have required permissions" do
        setup do
          login_as(FactoryBot.create(:user, name: "Stub User"))
          visit_draft_edition
        end

        should "not show 'Edit' link when user is not govuk editor or welsh editor" do
          within :css, ".editions__edit__summary" do
            assert page.has_no_link?("Edit")
          end
        end

        should "not show 'Edit' link when user is welsh editor and edition is not welsh" do
          login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
          visit_draft_edition

          within :css, ".editions__edit__summary" do
            assert page.has_no_link?("Edit")
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
                assert page.has_no_link?("Edit")
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
                assert page.has_link?("Edit")
              end
            end

            should "navigate to edit assignee page when 'Edit' assignee is clicked" do
              within :css, ".editions__edit__summary" do
                click_link("Edit")
              end

              assert(page.current_path.include?("/edit_assignee"))
            end
          end
        end

        context "edit assignee page" do
          setup do
            visit_draft_edition
            within :css, ".editions__edit__summary" do
              click_link("Edit")
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

    context "content block guidance" do
      context "when show_link_to_content_block_manager? is false" do
        setup do
          test_strategy = Flipflop::FeatureSet.current.test!
          test_strategy.switch!(:show_link_to_content_block_manager, false)
          visit_draft_edition
        end

        should "not show the content block guidance" do
          assert_not page.has_text?("Content block")
        end
      end

      context "when show_link_to_content_block_manager? is true" do
        setup do
          test_strategy = Flipflop::FeatureSet.current.test!
          test_strategy.switch!(:show_link_to_content_block_manager, true)
          visit_draft_edition
        end

        should "show the content block guidance" do
          assert page.has_text?("Content block")
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
        @draft_edition.artefact.external_links = [{ title: "Link One", url: "https://gov.uk" }]
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
        @draft_edition.artefact.external_links = [{ title: "Link One", url: "https://gov.uk" }]
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

private

  def visit_draft_edition
    @draft_edition = FactoryBot.create(:edition, title: "Edit page title", state: "draft", overview: "metatags", in_beta: 1, body: "The body")
    visit edition_path(@draft_edition)
  end

  def visit_published_edition
    create_published_edition
    visit edition_path(@published_edition)
  end

  def visit_fact_check_edition
    @fact_check_edition = FactoryBot.create(:edition, title: "Edit page title", state: "fact_check")
    visit edition_path(@fact_check_edition)
  end

  def visit_scheduled_for_publishing_edition
    @scheduled_for_publishing_edition = FactoryBot.create(:edition, title: "Edit page title", state: "scheduled_for_publishing", publish_at: Time.zone.now + 1.hour)
    visit edition_path(@scheduled_for_publishing_edition)
  end

  def visit_archived_edition
    @archived_edition = FactoryBot.create(:edition, title: "Edit page title", state: "archived")
    visit edition_path(@archived_edition)
  end

  def visit_in_review_edition
    @in_review_edition = FactoryBot.create(:edition, title: "Edit page title", state: "in_review", review_requested_at: 1.hour.ago)
    visit edition_path(@in_review_edition)
  end

  def visit_amends_needed_edition
    @amends_needed_edition = FactoryBot.create(:edition, title: "Edit page title", state: "amends_needed")
    visit edition_path(@amends_needed_edition)
  end

  def visit_fact_check_received_edition
    @fact_check_received_edition = FactoryBot.create(:edition, title: "Edit page title", state: "fact_check_received")
    visit edition_path(@fact_check_received_edition)
  end

  def visit_ready_edition
    @ready_edition = FactoryBot.create(:edition, title: "Edit page title", state: "ready")
    visit edition_path(@ready_edition)
  end

  def visit_new_edition_of_published_edition
    create_published_edition
    new_edition = FactoryBot.create(
      :answer_edition,
      panopticon_id: @published_edition.artefact.id,
      state: "draft",
      version_number: 2,
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
    visit edition_path(@published_edition)
  end

  def visit_retired_edition_in_published
    @published_edition = FactoryBot.create(
      :campaign_edition,
      state: "published",
    )
    visit edition_path(@published_edition)
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
end
