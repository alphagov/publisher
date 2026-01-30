require "integration_test_helper"

class EditScheduledForPublishingTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    login_as(@govuk_editor)
    @scheduled_for_publishing_edition = FactoryBot.create(:edition, :scheduled_for_publishing)

    visit edition_path(@scheduled_for_publishing_edition)
  end

  should "show common content-type fields" do
    assert page.has_css?("h3", text: "Title")
    assert page.has_css?("p", text: @scheduled_for_publishing_edition.title)
    assert page.has_css?("h3", text: "Meta tag description")
    assert page.has_css?("p", text: @scheduled_for_publishing_edition.overview)
    assert page.has_css?("h3", text: "Is this beta content?")
    assert page.has_css?("p", text: "No")

    @scheduled_for_publishing_edition.in_beta = true
    @scheduled_for_publishing_edition.save!(validate: false)
    visit edition_path(@scheduled_for_publishing_edition)

    assert page.has_css?("p", text: "Yes")
  end

  should "show body field" do
    assert page.has_css?("h3", text: "Body")
    assert page.has_css?("div", text: @scheduled_for_publishing_edition.body)
  end

  should "show public change field" do
    assert page.has_css?("h3", text: "Public change note")
    assert page.has_css?("p", text: "None added")

    @scheduled_for_publishing_edition.major_change = true
    @scheduled_for_publishing_edition.change_note = "Change note for test"
    @scheduled_for_publishing_edition.save!(validate: false)
    visit edition_path(@scheduled_for_publishing_edition)

    assert page.has_text?(@scheduled_for_publishing_edition.change_note)
  end

  should "show a preview link in the sidebar" do
    visit edition_path(@scheduled_for_publishing_edition)
    assert page.has_link?("Preview (opens in new tab)")
  end

  should "show a preview link when user is not an editor" do
    login_as(FactoryBot.create(:user, name: "Non Editor"))
    visit edition_path(@scheduled_for_publishing_edition)

    assert page.has_link?("Preview (opens in new tab)")
  end

  should "show a 'publish now' button in the sidebar when user is a govuk editor" do
    login_as_govuk_editor
    visit edition_path(@scheduled_for_publishing_edition)

    assert page.has_link?("Publish now", href: send_to_publish_page_edition_path(@scheduled_for_publishing_edition))
  end

  should "show a 'cancel scheduling' button in the sidebar when user is a govuk editor" do
    login_as_govuk_editor
    visit edition_path(@scheduled_for_publishing_edition)

    assert page.has_link?("Cancel scheduling", href: cancel_scheduled_publishing_page_edition_path(@scheduled_for_publishing_edition))
  end

  should "not show the 'Resend fact check email' link and text" do
    assert page.has_no_link?("Resend fact check email")
    assert page.has_no_text?("You've requested this edition to be fact checked. We're awaiting a response.")
  end

  context "that is welsh" do
    setup do
      @scheduled_for_publishing_edition = FactoryBot.create(:edition, :scheduled_for_publishing, :welsh)
    end

    should "show a 'publish now' button in the sidebar when user is a welsh editor" do
      login_as_welsh_editor
      visit edition_path(@scheduled_for_publishing_edition)

      assert page.has_link?("Publish now", href: send_to_publish_page_edition_path(@scheduled_for_publishing_edition))
    end

    should "not show a 'publish now' button in the sidebar when user is not a welsh editor" do
      login_as(FactoryBot.create(:user))
      visit edition_path(@scheduled_for_publishing_edition)

      assert page.has_no_link?("Publish now")
    end

    should "show a 'cancel scheduling' button in the sidebar when user is a welsh editor" do
      login_as_welsh_editor
      visit edition_path(@scheduled_for_publishing_edition)

      assert page.has_link?("Cancel scheduling", href: cancel_scheduled_publishing_page_edition_path(@scheduled_for_publishing_edition))
    end

    should "not show a 'cancel scheduling' button in the sidebar when user is not a welsh editor" do
      login_as(FactoryBot.create(:user))
      visit edition_path(@scheduled_for_publishing_edition)

      assert page.has_no_link?("Cancel scheduling")
    end
  end

  context "place edition" do
    should "show public change note field" do
      edition = FactoryBot.create(:place_edition, :scheduled_for_publishing)
      visit edition_path(edition)

      assert page.has_css?("h3", text: "Public change note")
      assert page.has_css?("p", text: "None added")

      edition.major_change = true
      edition.change_note = "Change note for test"
      edition.save!(validate: false)
      visit edition_path(edition)

      assert page.has_text?(edition.change_note)
    end
  end

  context "transaction edition" do
    should "show public change note field" do
      transaction_edition = FactoryBot.create(:transaction_edition, :scheduled_for_publishing)
      visit edition_path(transaction_edition)

      assert page.has_css?("h3", text: "Public change note")
      assert page.has_css?("p", text: "None added")

      transaction_edition.major_change = true
      transaction_edition.change_note = "Change note for test"
      transaction_edition.save!(validate: false)
      visit edition_path(transaction_edition)

      assert page.has_text?(transaction_edition.change_note)
    end
  end

  context "completed transaction edition" do
    should "show public change note field" do
      completed_transaction_edition = FactoryBot.create(:completed_transaction_edition, :scheduled_for_publishing)
      visit edition_path(completed_transaction_edition)

      assert page.has_css?("h3", text: "Public change note")
      assert page.has_css?("p", text: "None added")

      completed_transaction_edition.major_change = true
      completed_transaction_edition.change_note = "Change note for test"
      completed_transaction_edition.save!(validate: false)
      visit edition_path(completed_transaction_edition)

      assert page.has_text?(completed_transaction_edition.change_note)
    end
  end

  context "guide edition" do
    setup do
      @draft_guide_edition_with_parts = FactoryBot.create(:guide_edition_with_two_parts, :scheduled_for_publishing)
      visit edition_path(@draft_guide_edition_with_parts)
    end

    should "not show 'Add new chapter' button" do
      assert_not page.has_css?(".govuk-button", text: "Add a new chapter")
    end

    should "not show 'Reorder chapters' button even with two parts present" do
      assert page.has_no_link?("Reorder chapters")
    end

    should "not allow user to load reorder chapters page" do
      visit reorder_edition_guide_parts_path(@draft_guide_edition_with_parts)

      assert current_path == edition_path(@draft_guide_edition_with_parts)
      assert page.has_content?("You are not allowed to perform this action in the current state.")
    end
  end
end
