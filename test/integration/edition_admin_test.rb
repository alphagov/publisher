require "integration_test_helper"

class EditionAdminTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    login_as(@govuk_editor)
    @test_strategy = Flipflop::FeatureSet.current.test!
    @test_strategy.switch!(:design_system_edit_phase_3a, true)
  end

  context "user does not have required permissions" do
    setup do
      @draft_edition = FactoryBot.create(:edition, :draft)
    end

    should "not show when user is not govuk editor or welsh editor" do
      login_as(FactoryBot.create(:user, name: "Stub User"))
      visit edition_path(@draft_edition)

      assert page.has_no_text?("Admin")
    end

    should "not show when user is welsh editor and edition is not welsh" do
      login_as(FactoryBot.create(:user, :welsh_editor, name: "Stub User"))
      visit edition_path(@draft_edition)

      assert page.has_no_text?("Admin")
    end
  end

  context "user has required permissions" do
    %i[draft amends_needed in_review fact_check_received ready archived scheduled_for_publishing].each do |state|
      context "when state is '#{state}'" do
        should "not show the 'Update content type' form" do
          edition = FactoryBot.create(:edition, state)

          visit edition_path(edition)
          click_link("Admin")

          assert page.has_no_text?("Update content type")
        end
      end
    end

    %i[published archived scheduled_for_publishing].each do |state|
      context "when state is '#{state}'" do
        setup do
          edition = FactoryBot.create(:edition, state)
          visit edition_path(edition)
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
          edition = FactoryBot.create(:edition, state)
          visit edition_path(edition)
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
        @fact_check_edition = FactoryBot.create(:edition, :fact_check)
        visit edition_path(@fact_check_edition)
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
      setup do
        @published_edition = FactoryBot.create(:edition, :published)
      end

      context "edition is not the latest version of a publication" do
        should "not show the 'Update content type' form" do
          FactoryBot.create(:edition, :draft, panopticon_id: @published_edition.artefact.id)

          visit edition_path(@published_edition)
          click_link("Admin")

          assert page.has_no_text?("Update content type")
        end
      end

      context "content type is not retired, edition is the latest version of a publication" do
        setup do
          visit edition_path(@published_edition)
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
        @draft_edition = FactoryBot.create(:edition, :draft)
        visit edition_path(@draft_edition)
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
