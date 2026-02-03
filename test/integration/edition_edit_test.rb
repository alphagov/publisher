require "integration_test_helper"

class EditionEditTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    @govuk_requester = FactoryBot.create(:user, :govuk_editor, name: "Stub requester")
    login_as(@govuk_editor)
    @test_strategy = Flipflop::FeatureSet.current.test!
    UpdateWorker.stubs(:perform_async)
  end

  context "edit page" do
    should "show all the tabs when user has required permission and edition is published" do
      published_edition = FactoryBot.create(:edition, :published)
      visit edition_path(published_edition)

      assert page.has_text?("Edit")
      assert page.has_text?("Tagging")
      assert page.has_text?("Metadata")
      assert page.has_text?("History and notes")
      assert page.has_text?("Admin")
      assert page.has_text?("Related external links")
      assert page.has_text?("Unpublish")
    end

    should "show document summary and title" do
      published_edition = FactoryBot.create(:edition, :published, title: "Edit page title")
      visit edition_path(published_edition)

      assert page.has_title?("Edit page title")
      row = find_all(".govuk-summary-list__row")
      assert row[0].has_content?("Assigned to")
      assert row[1].has_text?("Content type")
      assert row[1].has_text?("Answer")
      assert row[2].has_text?("Edition")
      assert row[2].has_text?("1")
      assert row[2].has_text?("Published")
    end

    should "show scheduled date and time when an edition is scheduled for publishing" do
      travel_to Time.zone.local(2025, 3, 4, 17, 16, 15)
      scheduled_for_publishing_edition = FactoryBot.create(
        :edition,
        :scheduled_for_publishing,
        publish_at: Time.zone.now,
      )

      visit edition_path(scheduled_for_publishing_edition)

      row = find_all(".govuk-summary-list__row")
      assert_equal 4, row.count, "Expected four rows in the summary"
      assert row[2].has_text?(/Scheduled for publishing$/)
      assert row[3].has_text?("Scheduled")
      assert row[3].has_text?("5:16pm, 4 March 2025")
    end

    %i[draft amends_needed fact_check_received ready archived published].each do |state|
      should "not show a scheduled row when an edition is in the '#{state}' state" do
        edition = FactoryBot.create(:edition, state)
        visit edition_path(edition)

        row = find_all(".govuk-summary-list__row")
        assert_equal 3, row.count, "Expected three rows in the summary"
        assert page.has_no_content?("Scheduled")
      end
    end

    should "not show a scheduled row when an edition is in the 'in_review' state" do
      edition = FactoryBot.create(:edition, :in_review, review_requested_at: 1.hour.ago)
      visit edition_path(edition)

      row = find_all(".govuk-summary-list__row")
      assert_equal 4, row.count, "Expected four rows in the summary"
      assert page.has_no_content?("Scheduled")
    end

    should "indicate when an edition does not have an assignee" do
      published_edition = FactoryBot.create(:edition, :published)
      visit edition_path(published_edition)

      within all(".govuk-summary-list__row")[0] do
        assert_selector(".govuk-summary-list__key", text: "Assigned to")
        assert_selector(".govuk-summary-list__value", text: "None")
      end
    end

    should "show the person assigned to an edition" do
      draft_edition = FactoryBot.create(:edition, :draft)
      visit edition_path(draft_edition)

      within all(".govuk-summary-list__row")[0] do
        assert_selector(".govuk-summary-list__key", text: "Assigned to")
        assert_selector(".govuk-summary-list__value", text: draft_edition.assignee)
      end
    end

    should "not show the 2i reviewer row in the summary if the edition state is not 'in_review'" do
      %i[draft amends_needed fact_check fact_check_received ready scheduled_for_publishing published archived].each do |state|
        edition = FactoryBot.create(:edition, state)
        visit edition_path(edition)

        within :css, ".govuk-summary-list" do
          assert_no_selector(".govuk-summary-list__key", text: "2i reviewer")
        end
      end
    end

    should "show the 2i reviewer row in the summary correctly if the edition state is 'in_review' and a reviewer is not assigned" do
      in_review_edition = FactoryBot.create(:edition, :in_review)
      visit edition_path(in_review_edition)

      within all(".govuk-summary-list__row")[3] do
        assert_selector(".govuk-summary-list__key", text: "2i reviewer")
        assert_selector(".govuk-summary-list__value", text: "Not yet claimed")
      end
    end

    should "show the 2i reviewer row in the summary correctly if the edition state is 'in_review' and a reviewer is assigned" do
      edition = FactoryBot.create(:edition, :in_review, reviewer: @govuk_editor)
      visit edition_path(edition)

      within all(".govuk-summary-list__row")[3] do
        assert_selector(".govuk-summary-list__key", text: "2i reviewer")
        assert_selector(".govuk-summary-list__value", text: "Stub User")
      end
    end

    should "display the important note if an important note exists" do
      note_text = "This is really really urgent!"
      draft_edition = FactoryBot.create(:edition, :draft)
      create_important_note_for_edition(draft_edition, note_text)

      visit edition_path(draft_edition)

      within :css, ".govuk-notification-banner" do
        assert page.has_text?("Important")
        assert page.has_text?(note_text)
        assert page.has_text?(@govuk_editor.name)
        assert page.has_text?(Time.zone.today.to_date.to_fs(:govuk_date))
      end
    end

    should "display only the most recent important note at the top" do
      first_note = "This is really really urgent!"
      second_note = "This should display only!"
      draft_edition = FactoryBot.create(:edition, :draft)
      create_important_note_for_edition(draft_edition, first_note)
      create_important_note_for_edition(draft_edition, second_note)

      visit edition_path(draft_edition)

      assert page.has_text?("Important")
      assert page.has_text?(second_note)
      assert page.has_no_text?(first_note)
    end

    context "content block guidance" do
      context "when show_link_to_content_block_manager? is false" do
        setup do
          @test_strategy.switch!(:show_link_to_content_block_manager, false)
          @draft_edition = FactoryBot.create(:edition, :draft)
          visit edition_path(@draft_edition)
        end

        should "not show the content block guidance" do
          assert_not page.has_text?("Use Content Block Manager (opens in new tab) to create, edit and use standardised content across GOV.UK")
        end
      end

      context "when show_link_to_content_block_manager? is true" do
        setup do
          @test_strategy.switch!(:show_link_to_content_block_manager, true)
        end

        %i[draft ready published archived].each do |state|
          should "show the content block guidance with content in #{state} state" do
            transaction_edition = FactoryBot.create(:transaction_edition, state)
            visit edition_path(transaction_edition)

            assert page.has_text?("Use Content Block Manager (opens in new tab) to create, edit and use standardised content across GOV.UK")
          end

          should "not show the content block guidance when content type has no GOVSPEAK field in #{state} state" do
            completed_transaction_edition = FactoryBot.create(:completed_transaction_edition, state)
            visit edition_path(completed_transaction_edition)

            assert_not page.has_text?("Use Content Block Manager (opens in new tab) to create, edit and use standardised content across GOV.UK")
          end
        end
      end
    end
  end
end
