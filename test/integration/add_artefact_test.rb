require "integration_test_helper"

class AddArtefactTest < IntegrationTest
  setup do
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
    stub_events_for_all_content_ids
    stub_users_from_signon_api
    UpdateWorker.stubs(:perform_async)
    @test_strategy.switch!(:design_system_edit_phase_3b, true)
    @test_strategy.switch!(:design_system_edit_phase_4, true)
  end

  slug_prefix_for_kind = [%w[help_page help/], %w[completed_transaction done/]] +
    %w[answer guide place simple_smart_answer transaction].map { |kind| [kind, ""] }

  slug_prefix_for_kind.each do |kind, slug_prefix|
    should "be able to create a new '#{kind}' artefact" do
      FactoryBot.create(:artefact, kind: kind, slug: "#{slug_prefix}duplicate-slug")

      visit root_path
      click_link "Create new content"
      click_button "Continue"

      within ".govuk-error-summary" do
        assert page.has_content?("There is a problem")
        assert page.has_content?("Select a content type")
      end

      choose kind.humanize
      click_button "Continue"

      # 'English' language radio option should be selected by default
      assert_checked_field "English"

      choose "Welsh"
      click_button "Create content"

      within ".govuk-error-summary" do
        assert page.has_content?("There is a problem")
        assert page.has_link?("Enter a title", href: "#artefact_name")
        assert page.has_link?("Enter a slug", href: "#artefact_slug")
      end

      fill_in "Title", with: "Example title"
      fill_in "Slug", with: "example**title"
      click_button "Create content"

      within ".govuk-error-summary" do
        assert page.has_link?("Slug can only consist of lower case characters, numbers and hyphens", href: "#artefact_slug")
      end

      fill_in "Title", with: "Example title"
      fill_in "Slug", with: "#{slug_prefix}/example-title"
      click_button "Create content"

      within ".govuk-error-summary" do
        assert page.has_link?("Slug can only consist of lower case characters, numbers and hyphens", href: "#artefact_slug")
      end

      fill_in "Slug", with: "duplicate-slug"
      click_button "Create content"

      within ".govuk-error-summary" do
        assert page.has_link?("Slug has already been taken", href: "#artefact_slug")
      end

      fill_in "Slug", with: "example-title"
      click_button "Create content"

      artefact = Artefact.last
      assert_equal kind, artefact.kind
      assert_equal "Example title", artefact.name
      assert_equal "#{slug_prefix}example-title", artefact.slug
      assert_equal "cy", artefact.language
      assert_equal "publisher", artefact.owning_app

      edition = Edition.last
      assert_equal edition.artefact, artefact
      assert_current_path edition_path(edition.id)
    end
  end

  should "be able to create a new 'local_transaction' artefact" do
    FactoryBot.create(:local_service, lgsl_code: 1)
    FactoryBot.create(:artefact, kind: "local_transaction", slug: "duplicate-slug")

    visit root_path
    click_link "Create new content"
    click_button "Continue"

    within ".govuk-error-summary" do
      assert page.has_content?("There is a problem")
      assert page.has_content?("Select a content type")
    end

    choose "Local transaction"
    click_button "Continue"

    # 'English' language radio option should be selected by default
    assert_checked_field "English"

    choose "Welsh"
    click_button "Create content"

    within ".govuk-error-summary" do
      assert page.has_content?("There is a problem")
      assert page.has_link?("Enter a title", href: "#artefact_name")
      assert page.has_link?("Enter a slug", href: "#artefact_slug")
      assert page.has_link?("Enter a LGSL code", href: "#artefact_lgsl_code")
      assert page.has_link?("Enter a LGIL code", href: "#artefact_lgil_code")
    end

    fill_in "Title", with: "Example title"
    fill_in "Slug", with: "example**title"
    fill_in "LGSL code", with: 2
    fill_in "LGIL code", with: "invalid"
    click_button "Create content"

    within ".govuk-error-summary" do
      assert page.has_link?("Slug can only consist of lower case characters, numbers and hyphens", href: "#artefact_slug")
      assert page.has_link?("LGSL code is not recognised", href: "#artefact_lgsl_code")
      assert page.has_link?("LGIL code can only be a whole number between 0 and 999", href: "#artefact_lgil_code")
    end

    fill_in "Title", with: "Example title"
    fill_in "Slug", with: "duplicate-slug"
    fill_in "LGSL code", with: 1
    fill_in "LGIL code", with: 2
    click_button "Create content"

    within ".govuk-error-summary" do
      assert page.has_link?("Slug has already been taken", href: "#artefact_slug")
    end

    fill_in "Slug", with: "example-title"
    click_button "Create content"

    artefact = Artefact.last
    assert_equal "local_transaction", artefact.kind
    assert_equal "Example title", artefact.name
    assert_equal "example-title", artefact.slug
    assert_equal "cy", artefact.language
    assert_equal "publisher", artefact.owning_app

    edition = Edition.last
    assert_equal edition.artefact, artefact

    local_transaction_edition = LocalTransactionEdition.last
    assert_equal 1, local_transaction_edition.lgsl_code
    assert_equal 2, local_transaction_edition.lgil_code
    assert_equal local_transaction_edition.edition, edition
    assert_current_path edition_path(edition.id)
  end
end
