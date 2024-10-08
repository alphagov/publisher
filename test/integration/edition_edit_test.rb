require "integration_test_helper"

class EditionEditTest < IntegrationTest
  setup do
    setup_users
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_edit, true)
    stub_linkables
  end

  context "when edition is draft" do
    setup do
      edition = FactoryBot.create(:guide_edition, title: "Edit page title", state: "draft")
      visit edition_path(edition)
    end

    should "show document summary and title" do
      assert page.has_title?("Edit page title")

      row = find_all(".govuk-summary-list__row")
      assert row[0].has_content?("Assigned to")
      assert row[1].has_text?("Content type")
      assert row[1].has_text?("Guide")
      assert row[2].has_text?("Edition")
      assert row[2].has_text?("1")
      assert row[2].has_text?("Draft")
    end

    should "show all the tabs for the edit" do
      assert page.has_text?("Edit")
      assert page.has_text?("Tagging")
      assert page.has_text?("Metadata")
      assert page.has_text?("History and notes")
      assert page.has_text?("Admin")
      assert page.has_text?("Related external links")
      assert page.has_text?("Unpublish")
    end

    context "metadata tab" do
      setup do
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
  end

  context "when edition is published" do
    context "metadata tab" do
      setup do
        edition = FactoryBot.create(
          :completed_transaction_edition,
          panopticon_id: FactoryBot.create(
            :artefact,
            slug: "can-i-get-a-driving-licence",
          ).id,
          state: "published",
          slug: "can-i-get-a-driving-licence",
        )

        visit edition_path(edition)
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
end
