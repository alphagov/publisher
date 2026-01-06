require "integration_test_helper"

class EditionMetadataTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    login_as(@govuk_editor)
    @test_strategy = Flipflop::FeatureSet.current.test!
    @test_strategy.switch!(:design_system_edit_phase_3a, true)
    UpdateWorker.stubs(:perform_async)
  end

  context "when state is 'draft' and user has govuk editor permissions" do
    setup do
      @draft_edition = FactoryBot.create(:edition, :draft)
      visit edition_path(@draft_edition)
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
      artefact = FactoryBot.create(:artefact, slug: "welsh-language-edition-test", language: "cy")
      welsh_edition = FactoryBot.create(
        :edition,
        :welsh,
        :ready,
        panopticon_id: artefact.id,
        slug: "welsh-language-edition-test",
      )
      login_as_welsh_editor

      visit edition_path(welsh_edition)
      click_link("Metadata")

      assert @user.has_editor_permissions?(welsh_edition)
      assert page.has_no_field?("artefact[slug]")
      assert page.has_no_field?("artefact[language]")
      assert page.has_text?("Slug")
      assert page.has_text?(/welsh-language-edition-test/)
      assert page.has_text?("Language")
      assert page.has_text?(/Welsh/)
      assert page.has_no_button?("Update")
    end

    should "show read-only values and no 'Update' button for a non-welsh edition" do
      draft_edition = FactoryBot.create(:edition, :draft)
      login_as_welsh_editor

      visit edition_path(draft_edition)
      click_link("Metadata")

      assert_not @user.has_editor_permissions?(draft_edition)
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
      draft_edition = FactoryBot.create(:edition, :draft)
      login_as(user)

      visit edition_path(draft_edition)
      click_link("Metadata")

      assert_not user.has_editor_permissions?(draft_edition)
      assert page.has_no_button?("Update")
    end
  end

  context "when state is not 'draft'" do
    setup do
      @artefact = FactoryBot.create(:artefact, slug: "can-i-get-a-driving-licence")
      @published_edition = FactoryBot.create(:edition, :published, slug: "can-i-get-a-driving-licence", panopticon_id: @artefact.id)
      visit edition_path(@published_edition)
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
