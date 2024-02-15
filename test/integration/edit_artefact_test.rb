require "integration_test_helper"

class EditArtefactTest < ActionDispatch::IntegrationTest
  context "edit" do
    setup do
      setup_users
      stub_linkables
      stub_holidays_used_by_fact_check
    end

    should "edit a draft artefact" do
      edition = FactoryBot.create(:edition)
      visit metadata_edition_path(edition)

      fill_in "Slug", with: ""
      click_button "Update metadata"

      assert page.has_content?("Enter a slug")

      fill_in "Slug", with: "thingy-mc-thingface"

      UpdateWorker.expects(:perform_async).with(edition.id.to_s)
      click_button "Update metadata"
      edition.reload

      assert page.has_content?("Metadata updated")
      assert edition.artefact.slug == "thingy-mc-thingface"
    end

    should "not be able to edit metadata for a published edition" do
      edition = FactoryBot.create(:edition, :published)
      visit metadata_edition_path(edition)

      assert_not page.has_button?("Update metadata")
    end
  end

  context "Claim 2i:" do
    setup do
      stub_linkables
      stub_holidays_used_by_fact_check
    end

    should "show 'Claim 2i' button on the Edit page for users who are not the Assignee" do
      user = FactoryBot.create(:user, :govuk_editor)
      assignee = FactoryBot.create(:user, :govuk_editor)
      edition = FactoryBot.create(
        :guide_edition,
        title: "XXX",
        state: "in_review",
        review_requested_at: Time.zone.now,
        assigned_to: assignee,
      )

      visit edition_path(edition)

      within("#edition-form") do
        find_button("Claim 2i").click
      end

      assert edition_url(edition), current_url
      assert page.has_content?("You are the reviewer of this guide.")
      assert page.has_select?("Assigned to", selected: assignee.name)
      assert page.has_select?("Reviewer", selected: user.name)
    end

    should "not show 'Claim 2i' button on the Edit page for the Assignee" do
      assignee = FactoryBot.create(:user, :govuk_editor)
      edition = FactoryBot.create(
        :guide_edition,
        title: "XXX",
        state: "in_review",
        review_requested_at: Time.zone.now,
        assigned_to: assignee,
      )

      visit edition_path(edition)

      assert edition_url(edition), current_url
      assert page.has_select?("Assigned to", selected: assignee.name)
      assert page.has_select?("Reviewer")
      assert page.has_no_select?("Reviewer", selected: assignee.name)
      assert page.has_no_css?("input", class: "claim-2i")
    end
  end
end
