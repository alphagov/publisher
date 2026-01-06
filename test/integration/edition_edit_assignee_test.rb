require "integration_test_helper"

class EditionEditAssigneeTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    @govuk_requester = FactoryBot.create(:user, :govuk_editor, name: "Stub requester")
    login_as(@govuk_editor)
    @test_strategy = Flipflop::FeatureSet.current.test!
    @test_strategy.switch!(:design_system_edit_phase_3a, true)
    UpdateWorker.stubs(:perform_async)
  end

  context "user does not have required permissions" do
    setup do
      login_as(FactoryBot.create(:user, name: "Stub User"))
      @draft_edition = FactoryBot.create(:edition, :draft)
      visit edition_path(@draft_edition)
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
      visit edition_path(@draft_edition)

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
          edition = FactoryBot.create(:edition, state)
          visit edition_path(edition)
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
          edition = FactoryBot.create(:edition, state)
          visit edition_path(edition)
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
        @draft_edition = FactoryBot.create(:edition, :draft)
        visit edition_path(@draft_edition)
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

      should "only show editors as available for assignment" do
        edition = FactoryBot.create(:edition, :draft)
        non_editor_user = FactoryBot.create(:user, name: "Non Editor User")

        visit edit_assignee_edition_path(edition)

        assert_selector "label", text: @govuk_editor.name
        assert_no_selector "label", text: non_editor_user.name
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
