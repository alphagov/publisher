require "legacy_integration_test_helper"

class SkipReviewTest < LegacyJavascriptIntegrationTest
  setup do
    @permitted_user = FactoryBot.create(
      :user,
      name: "Vincent Panache",
      email: "test@example.com",
      permissions: %w[skip_review govuk_editor],
    )

    stub_linkables
    stub_holidays_used_by_fact_check
    stub_events_for_all_content_ids
    stub_users_from_signon_api
    UpdateWorker.stubs(:perform_async)

    @artefact = FactoryBot.create(
      :artefact,
      slug: "hedgehog-topiary",
      kind: "simple_smart_answer",
      name: "Foo bar",
      owning_app: "publisher",
    )

    @simple_smart_answer = FactoryBot.create(
      :simple_smart_answer_edition,
      panopticon_id: @artefact.id,
      title: "Foo bar",
      state: "in_review",
      review_requested_at: 1.hour.ago,
    )

    @simple_smart_answer.new_action(@permitted_user, Action::REQUEST_REVIEW)
  end

  teardown do
    GDS::SSO.test_user = nil
  end

  should "allow a user with the correct permissions to skip review" do
    login_as @permitted_user

    visit "/publications/#{@artefact.id}"

    within(".alert-info:not(.alert-link-info)") do
      assert page.has_content? "Skip review"
      click_on "Skip review"
    end

    # Fill out review modal
    fill_in "Comment", with: "Vincent Panache can skip reviews"
    click_button "Skip review"

    within(".page-title .label-info") do
      assert page.has_content? "Ready"
    end

    within(".workflow-buttons.navbar-btn") do
      assert page.has_css?(".btn-primary", text: "Publish")
    end
  end

  should "not allow a user without permissions to skip review" do
    editor = FactoryBot.create(
      :user,
      name: "Editor",
      email: "thingy@example.com",
      permissions: %w[govuk_editor],
    )

    login_as editor

    visit "/publications/#{@artefact.id}"

    within(".alert-info:not(.alert-link-info)") do
      assert page.has_no_content? "Skip review"
    end

    within(".workflow-buttons.navbar-btn") do
      assert page.has_css?(".btn-primary.disabled", text: "Publish")
    end
  end
end
