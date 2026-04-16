require "integration_test_helper"
require "support/ga4_test_helpers"

class Ga4TrackingFlashMessagesTest < JavascriptIntegrationTest
  include Ga4TestHelpers

  setup do
    setup_users
    @edition = FactoryBot.create(:edition)
    @ready_edition = FactoryBot.create(:edition, :ready)
    @published_edition = FactoryBot.create(:edition, :published)
  end

  context "Danger alerts" do
    should "push the correct values to the dataLayer when a welsh_editor attempts to navigate to the 'Create new content' page" do
      login_as_welsh_editor
      visit new_artefact_path

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "You do not have permission to see this page.", event_data[0]["text"]
    end

    should "push the correct values to the dataLayer when user does not have govuk_editor permission" do
      login_as(@no_editor)
      visit history_update_important_note_edition_path(@edition)

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "You do not have correct editor permissions for this action.", event_data[0]["text"]
    end

    should "push the correct values to the dataLayer on a server error" do
      EditionProgressor.any_instance.expects(:progress).returns(false)

      visit send_to_2i_page_edition_path(@edition)
      fill_in "Comment (optional)", with: "Some comment"
      click_button "Send to 2i"

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "Due to a service problem, the request could not be made", event_data[0]["text"]
    end

    should "push the correct values to the dataLayer when the edition is not in a valid state to be sent to 2i" do
      visit send_to_2i_page_edition_path(@ready_edition)
      fill_in "Comment (optional)", with: "Some comment"
      click_button "Send to 2i"

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "danger_alerts", event_data[0]["action"]
      assert_equal "flash_danger", event_data[0]["event_name"]
      assert_equal "Edition is not in a state where it can be sent to 2i", event_data[0]["text"]
    end
  end

  context "Warning alerts" do
    should "push the correct values to the dataLayer when another user has already created a new edition" do
      visit edition_path(@published_edition)
      click_on "Admin"

      FactoryBot.create(:edition, panopticon_id: @published_edition.artefact.id)

      click_button "Save"

      assert page.has_css?(".gem-c-error-alert")

      event_data = get_event_data

      assert_equal "warning_alerts", event_data[0]["action"]
      assert_equal "flash_warning", event_data[0]["event_name"]
      assert_equal "Another person has created a newer edition", event_data[0]["text"]
    end
  end

  context "Success alerts" do
    should "push the correct flash message values to the dataLayer when edition is successfully saved" do
      visit edition_path(@edition)
      fill_in "Title", with: "The new title"
      click_button "Save"

      assert page.has_css?(".gem-c-success-alert")

      event_data = get_event_data

      assert_equal "success_alerts", event_data[0]["action"]
      assert_equal "flash_success", event_data[0]["event_name"]
      assert_equal "Edition updated successfully.", event_data[0]["text"]
    end

    should "push the correct flash message values to the dataLayer when edition is successfully sent to 2i" do
      visit send_to_2i_page_edition_path(@edition)
      fill_in "Comment (optional)", with: "Some comment"
      click_button "Send to 2i"

      assert page.has_css?(".gem-c-success-alert")

      event_data = get_event_data

      assert_equal "success_alerts", event_data[0]["action"]
      assert_equal "flash_success", event_data[0]["event_name"]
      assert_equal "Sent to 2i", event_data[0]["text"]
    end
  end
end
