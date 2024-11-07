require "integration_test_helper"

class EditionEditTest < IntegrationTest
  setup do
    login_as(FactoryBot.create(:user, :govuk_editor, name: "Stub User"))
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_edit, true)
    stub_linkables
  end

  context "all tabs" do
    setup do
      visit_edition_in_published
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
  end

  context "metadata tab" do
    context "when state is 'draft'" do
      setup do
        visit_edition_in_draft
        click_link("Metadata")
      end

      should "show 'Metadata' header and an update button" do
        within :css, ".gem-c-heading" do
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
        visit_edition_in_published
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
    context "do not have required permissions" do
      setup do
        login_as(FactoryBot.create(:user, name: "Stub User"))
        visit_edition_in_draft
      end

      should "not show unpublish tab when user is not govuk editor" do
        assert page.has_no_text?("Unpublish")
      end
    end

    context "has required permissions" do
      setup do
        login_as(FactoryBot.create(:user, :govuk_editor, name: "Stub User"))
        visit_edition_in_draft
      end

      context "when state is 'published'" do
        setup do
          visit_edition_in_published
          click_link("Unpublish")
        end

        should "show 'Unpublish' header and 'Continue' button" do
          within :css, ".gem-c-heading" do
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
    context "do not have required permissions" do
      setup do
        login_as(FactoryBot.create(:user, name: "Stub User"))
        visit_edition_in_draft
      end

      should "not show when user is not govuk editor or welsh editor" do
        assert page.has_no_text?("Admin")
      end

      should "not show when user is welsh editor and edition is not welsh" do
        login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
        visit_edition_in_draft

        assert page.has_no_text?("Admin")
      end
    end

    context "has required permissions" do
      setup do
        login_as(FactoryBot.create(:user, :govuk_editor, name: "Stub User"))
      end

      context "when state is not 'fact_check'" do
        setup do
          visit_edition_in_draft
          click_link("Admin")
        end

        should "show 'Admin' header and not show 'Skip fact check' button" do
          within :css, ".gem-c-heading" do
            assert page.has_text?("Admin")
          end
          assert page.has_no_button?("Skip fact check")
        end
      end

      context "when state is 'fact_check'" do
        setup do
          visit_edition_in_fact_check
          click_link("Admin")
        end

        should "show tab when user is welsh editor and edition is welsh edition" do
          login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
          welsh_edition = FactoryBot.create(:edition, :fact_check, :welsh)
          visit edition_path(welsh_edition)

          assert page.has_text?("Admin")
        end

        should "show 'Admin' header and an 'Skip fact check' button" do
          within :css, ".gem-c-heading" do
            assert page.has_text?("Admin")
          end
          assert page.has_button?("Skip fact check")
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
    end
  end

  context "edit tab" do
    context "draft edition of a new publication" do
      setup do
        visit_edition_in_draft
      end

      should "show 'Metadata' header and an update button" do
        within :css, "h2.gem-c-heading" do
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
  end

private

  def visit_edition_in_draft
    @draft_edition = FactoryBot.create(
      :answer_edition,
      title: "Edit page title",
      state: "draft",
      overview: "metatags",
      in_beta: 1,
      body: "The body",
    )
    visit edition_path(@draft_edition)
  end

  def visit_edition_in_published
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

  def visit_edition_in_fact_check
    @fact_check_edition = FactoryBot.create(:edition, title: "Edit page title", state: "fact_check")
    visit edition_path(@fact_check_edition)
  end

  def visit_new_edition_of_published_edition
    published_edition = FactoryBot.create(
      :answer_edition,
      panopticon_id: FactoryBot.create(
        :artefact,
        slug: "can-i-get-a-driving-licence",
      ).id,
      state: "published",
      slug: "can-i-get-a-driving-licence",
    )
    new_edition = FactoryBot.create(
      :answer_edition,
      panopticon_id: published_edition.artefact.id,
      state: "draft",
      version_number: 2,
      change_note: "The change note",
    )
    visit edition_path(new_edition)
  end
end
