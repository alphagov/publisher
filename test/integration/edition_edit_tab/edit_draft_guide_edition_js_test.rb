require "integration_test_helper"

class EditDraftGuideEditionJsTest < JavascriptIntegrationTest
  context "auto-population of a chapter's slug from its title when JS is enabled" do
    setup do
      login_as_govuk_editor
    end

    should "auto-populate the chapter's slug from the title" do
      @draft_edition = FactoryBot.create(:guide_edition, :draft)
      visit edition_path(@draft_edition)
      click_on "Add a new chapter"

      fill_in "part[title]", with: "Some Title"
      find_field("part[title]").send_keys(:tab)

      assert page.has_field?("part[slug]", with: "some-title")
    end

    context "when it's the first edition" do
      should "overwrite the chapter's slug when changing the title" do
        @draft_edition = FactoryBot.create(:guide_edition, :draft)
        @part = @draft_edition.parts.create(title: "Original", slug: "original")
        visit edit_edition_guide_part_path(@draft_edition, @part)

        fill_in "part[title]", with: "Changed"
        find_field("part[title]").send_keys(:tab)

        slug_field = find_field("part[slug]")
        assert_equal "changed", slug_field.value
      end
    end

    context "when it's not the first edition" do
      should "not overwrite the chapter's slug when changing the title" do
        @published_edition = FactoryBot.create(:guide_edition, :published)
        @draft_edition = @published_edition.build_clone
        @draft_edition.save!
        @part = @draft_edition.parts.create(title: "Original", slug: "original")
        visit edit_edition_guide_part_path(@draft_edition, @part)

        fill_in "part[title]", with: "Changed"
        find_field("part[title]").send_keys(:tab)

        slug_field = find_field("part[slug]")
        assert_equal "original", slug_field.value
      end
    end
  end
end
