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

  context "chapter accordion display when JS is enabled" do
    setup do
      login_as_govuk_editor
      @test_strategy.switch!(:guide_chapter_accordion_interface, true)
      @draft_guide_edition_with_parts = FactoryBot.create(:guide_edition_with_two_parts)
      @part_1 = @draft_guide_edition_with_parts.parts.first
      @part_2 = @draft_guide_edition_with_parts.parts.second
      visit edition_path(@draft_guide_edition_with_parts)
    end

    should "show chapters in collapsed state by default" do
      assert_button "Show all sections"

      within all(".govuk-accordion__section")[0] do
        assert_button "Show"
        assert_field "edition[parts_attributes][][title]", with: @part_1.title, visible: false
        assert_field "edition[parts_attributes][][slug]", with: @part_1.slug, visible: false
        assert_field "edition[parts_attributes][][body]", with: @part_1.body, visible: false
        assert_link "Delete chapter", visible: false
      end

      within all(".govuk-accordion__section")[1] do
        assert_button "Show"
        assert_field "edition[parts_attributes][][title]", with: @part_2.title, visible: false
        assert_field "edition[parts_attributes][][slug]", with: @part_2.slug, visible: false
        assert_field "edition[parts_attributes][][body]", with: @part_2.body, visible: false
        assert_link "Delete chapter", visible: false
      end
    end

    should "expand a chapter when the 'Show' button is clicked" do
      within all(".govuk-accordion__section")[0] do
        click_button "Show"

        assert_button "Hide"
        assert_field "edition[parts_attributes][][title]", with: @part_1.title, visible: true
        assert_field "edition[parts_attributes][][slug]", with: @part_1.slug, visible: true
        assert_field "edition[parts_attributes][][body]", with: @part_1.body, visible: true
        assert_link "Delete chapter", visible: true
      end

      within all(".govuk-accordion__section")[1] do
        assert_button "Show"
        assert_field "edition[parts_attributes][][title]", with: @part_2.title, visible: false
        assert_field "edition[parts_attributes][][slug]", with: @part_2.slug, visible: false
        assert_field "edition[parts_attributes][][body]", with: @part_2.body, visible: false
        assert_link "Delete chapter", visible: false
      end
    end

    should "expand all chapters when the 'Show all sections' button is clicked" do
      click_button "Show all sections"

      assert_button "Hide all sections"

      within all(".govuk-accordion__section")[0] do
        assert_button "Hide"
        assert_field "edition[parts_attributes][][title]", with: @part_1.title, visible: true
        assert_field "edition[parts_attributes][][slug]", with: @part_1.slug, visible: true
        assert_field "edition[parts_attributes][][body]", with: @part_1.body, visible: true
        assert_link "Delete chapter", visible: true
      end

      within all(".govuk-accordion__section")[1] do
        assert_button "Hide"
        assert_field "edition[parts_attributes][][title]", with: @part_2.title, visible: true
        assert_field "edition[parts_attributes][][slug]", with: @part_2.slug, visible: true
        assert_field "edition[parts_attributes][][body]", with: @part_2.body, visible: true
        assert_link "Delete chapter", visible: true
      end
    end

    should "expand a chapter by default when it contains an error message" do
      within all(".govuk-accordion__section")[0] do
        click_button "Show"
        fill_in "Title", with: ""
      end

      click_button "Save"

      within ".govuk-error-summary" do
        assert_text "There is a problem"
        assert_link "Enter a title for Chapter 1", href: "#part_1_title"
      end

      within all(".govuk-accordion__section")[0] do
        assert_button "Hide"
        assert_text "Enter a title for Chapter 1"
        assert_field "edition[parts_attributes][][title]", with: "", visible: true
        assert_field "edition[parts_attributes][][slug]", with: @part_1.slug, visible: true
        assert_field "edition[parts_attributes][][body]", with: @part_1.body, visible: true
        assert_link "Delete chapter", visible: true
      end

      within all(".govuk-accordion__section")[1] do
        assert_button "Show"
        assert_field "edition[parts_attributes][][title]", with: @part_2.title, visible: false
        assert_field "edition[parts_attributes][][slug]", with: @part_2.slug, visible: false
        assert_field "edition[parts_attributes][][body]", with: @part_2.body, visible: false
        assert_link "Delete chapter", visible: false
      end
    end
  end
end
