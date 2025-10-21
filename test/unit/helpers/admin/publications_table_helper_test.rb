require "test_helper"

class PublicationsTableHelperTest < ActionView::TestCase
  include PublicationsTableHelper

  context "#edition_number" do
    should "return the edition number for an edition that is not archived or published " do
      edition = FactoryBot.create(
        :edition,
        state: "draft",
        version_number: 1,
      )

      assert_equal "1", edition_number(edition)
    end

    should "return the edition number text for a published edition where a newer edition has been created" do
      artefact = FactoryBot.create(:artefact)
      published_edition = FactoryBot.create(
        :edition,
        panopticon_id: artefact.id,
        state: "published",
        version_number: 1,
        sibling_in_progress: 2,
      )
      FactoryBot.create(
        :edition,
        panopticon_id: artefact.id,
        state: "draft",
        version_number: 2,
      )

      edition_number_text = edition_number(published_edition)

      assert_match "1 - ", edition_number_text
      assert_match "#2 in draft", edition_number_text
    end

    should "return the edition number text for an archived edition where a newer edition has been created" do
      artefact = FactoryBot.create(:artefact)
      archived_edition = FactoryBot.create(
        :edition,
        panopticon_id: artefact.id,
        state: "archived",
        version_number: 2,
        sibling_in_progress: 3,
      )
      FactoryBot.create(
        :edition,
        panopticon_id: artefact.id,
        state: "in_review",
        review_requested_at: "2024-07-12 11:25:35.297 UTC",
        version_number: 3,
      )

      edition_number_text = edition_number(archived_edition)

      assert_match "2 - ", edition_number_text
      assert_match "#3 in in review", edition_number_text
    end
  end

  context "#important_note" do
    should "return the important note text for an edition" do
      user = FactoryBot.create(:user, name: "Keir Starmer")
      edition_without_important_note = FactoryBot.create(:edition)
      edition_with_important_note = FactoryBot.create(:edition)
      user.record_note(edition_with_important_note, "This is an important note", Action::IMPORTANT_NOTE)

      assert_nil important_note(edition_without_important_note)
      assert_equal "This is an important note", important_note(edition_with_important_note)
    end
  end

  context "#awaiting_review" do
    should "return the correct text for an edition in review" do
      today = Date.parse("2024-08-02")

      Timecop.freeze(today) do
        edition_draft = FactoryBot.create(
          :edition,
          state: "draft",
        )

        edition_in_review = FactoryBot.create(
          :edition,
          state: "in_review",
          review_requested_at: "2024-07-12",
        )

        assert_nil awaiting_review(edition_draft)
        assert_equal "21 days", awaiting_review(edition_in_review)
      end
    end
  end

  context "#scheduled" do
    should "return the correct text for an edition that is scheduled for publishing" do
      today = Date.parse("2024-08-02")

      Timecop.freeze(today) do
        edition_published = FactoryBot.create(
          :edition,
          state: "published",
        )

        edition_scheduled_for_publishing = FactoryBot.create(
          :edition,
          state: "scheduled_for_publishing",
          publish_at: "2024-08-21 10:04:50.119 UTC",
        )

        assert_nil scheduled(edition_published)
        assert_equal "11:04am, 21 Aug 2024", scheduled(edition_scheduled_for_publishing)
      end
    end
  end

  context "#published_by" do
    should "return the correct text for a published edition" do
      today = Date.parse("2024-08-02")

      Timecop.freeze(today) do
        edition_scheduled_for_publishing = FactoryBot.create(
          :edition,
          state: "scheduled_for_publishing",
          publish_at: "2024-09-21",
        )

        edition_published = FactoryBot.create(
          :edition,
          state: "published",
          publisher: "Keir Starmer",
        )

        assert_nil published_by(edition_scheduled_for_publishing)
        assert_equal "Keir Starmer", published_by(edition_published)
      end
    end
  end

  context "#reviewer" do
    should "return the correct text for the '2i reviewer' field for an edition that is not in review" do
      current_user = FactoryBot.create(:user, name: "Liz Truss", permissions: %w[govuk_editor])
      edition = FactoryBot.create(
        :edition,
        state: "draft",
      )

      assert_nil reviewer(edition, current_user)
    end

    should "return an edition's reviewer when there is one" do
      current_user = FactoryBot.create(:user, name: "Boris Johnson", permissions: %w[govuk_editor])
      edition = FactoryBot.create(
        :edition,
        state: "in_review",
        review_requested_at: "2024-07-12",
        reviewer: "Rishi Sunak",
      )

      assert_equal "Rishi Sunak", reviewer(edition, current_user)
    end

    should "return nil when an edition assigned to the current user is in review and has not yet been claimed" do
      current_user = FactoryBot.create(:user, name: "Theresa May", permissions: %w[govuk_editor])
      edition = FactoryBot.create(
        :edition,
        state: "in_review",
        review_requested_at: "2024-07-12",
        assigned_to_id: current_user.id,
      )

      assert_nil reviewer(edition, current_user)
    end

    should "return a form for claiming a review when an edition assigned to another user is in review and has not been claimed and the current user may do so" do
      current_user = FactoryBot.create(:user, name: "David Cameron", permissions: %w[govuk_editor])
      another_user = FactoryBot.create(:user, name: "Another User", permissions: %w[govuk_editor])
      edition = FactoryBot.create(
        :edition,
        state: "in_review",
        review_requested_at: "2024-07-12",
        assigned_to_id: another_user.id,
      )

      assert_includes reviewer(edition, current_user), '<button class="gem-c-button govuk-button" type="submit">Claim 2i</button>'
    end

    should "return nil when an edition assigned to another user is in review and has not been claimed and the current user may not do so" do
      current_user = FactoryBot.create(:user, name: "Gordon Brown")
      another_user = FactoryBot.create(:user, name: "Another User")
      edition = FactoryBot.create(
        :edition,
        state: "in_review",
        review_requested_at: "2024-07-12",
        assigned_to_id: another_user.id,
      )

      assert_nil reviewer(edition, current_user)
    end
  end

  context "#format" do
    should "return the correct value for the format" do
      service = LocalService.create!(lgsl_code: 1, providing_tier: %w[county unitary])
      edition_answer = FactoryBot.create(:answer_edition)
      edition_completed_transaction = FactoryBot.create(:completed_transaction_edition)
      edition_guide = FactoryBot.create(:guide_edition)
      edition_help_page = FactoryBot.create(:help_page_edition)
      edition_local_transaction = FactoryBot.create(:local_transaction_edition, panopticon_id: FactoryBot.create(:artefact).id, lgsl_code: service.lgsl_code, lgil_code: 1)
      edition_place = FactoryBot.create(:place_edition)
      edition_simple_smart_answer = FactoryBot.create(:simple_smart_answer_edition)
      edition_transaction = FactoryBot.create(:transaction_edition)

      assert_equal "Answer", format(edition_answer)
      assert_equal "Completed transaction", format(edition_completed_transaction)
      assert_equal "Guide", format(edition_guide)
      assert_equal "Help page", format(edition_help_page)
      assert_equal "Local transaction", format(edition_local_transaction)
      assert_equal "Place", format(edition_place)
      assert_equal "Simple smart answer", format(edition_simple_smart_answer)
      assert_equal "Transaction", format(edition_transaction)
    end
  end

  context "#sent_out" do
    should "return the correct text for an edition in Fact Check" do
      today = Date.parse("2024-08-02")
      edition = FactoryBot.create(
        :edition,
        state: "fact_check",
      )

      Timecop.freeze(today) do
        send_fact_check_action = Action.new(
          request_type: "send_fact_check",
          edition: edition,
        )
        send_fact_check_action.save!
        edition.stubs(:actions).returns([send_fact_check_action])
      end

      assert_equal "2 Aug 2024", sent_out(edition)
    end

    should "return nil for an edition not in Fact Check" do
      edition = FactoryBot.create(
        :edition,
        state: "draft",
      )

      assert_nil sent_out(edition)
    end
  end
end
