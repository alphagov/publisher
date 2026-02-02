require "legacy_integration_test_helper"

class HostContentUpdateHistoryTest < LegacyJavascriptIntegrationTest
  setup do
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
  end

  context "Viewing content update history" do
    setup do
      user1 = {
        "uid" => SecureRandom.uuid,
        "name" => "User 1",
        "email" => "user1@example.com",
      }

      user2 = {
        "uid" => SecureRandom.uuid,
        "name" => "User 2",
        "email" => "user2@example.com",
      }

      @host_content_update_events = []

      @out_of_scope_content_update_event = create_content_update_event(
        updated_by_user_uid: user1["uid"],
      )

      some_time_passes
      edition1 = FactoryBot.create(:answer_edition, slug: "test-slug")

      some_time_passes
      edition1.new_action(@author, Action::SEND_FACT_CHECK)

      some_time_passes
      edition1.new_action(@author, Action::RECEIVE_FACT_CHECK)

      some_time_passes
      edition1.new_action(@author, Action::PUBLISH)
      edition1.state = "published"
      edition1.save!

      some_time_passes
      @edition1_content_update_event = create_content_update_event(
        updated_by_user_uid: user1["uid"],
      )

      some_time_passes
      edition2 = edition1.build_clone
      edition2.save!

      some_time_passes
      edition2.new_action(@author, Action::SEND_FACT_CHECK)

      some_time_passes
      edition2.new_action(@author, Action::RECEIVE_FACT_CHECK)

      some_time_passes
      edition2.new_action(@author, Action::PUBLISH)
      edition1.state = "archived"
      edition1.save!
      edition2.state = "published"
      edition2.save!

      some_time_passes
      @edition2_content_update_event_1 = create_content_update_event(
        updated_by_user_uid: user2["uid"],
      )

      some_time_passes
      @edition2_content_update_event_2 = create_content_update_event(
        updated_by_user_uid: user1["uid"],
      )

      some_time_passes
      @edition3 = edition2.build_clone(SimpleSmartAnswerEdition)
      @edition3.save!

      all_events = [
        @out_of_scope_content_update_event,
        @edition1_content_update_event,
        @edition2_content_update_event_1,
        @edition2_content_update_event_2,
      ]

      stub_events_for_all_content_ids(events: all_events)
      stub_users_from_signon_api([user1["uid"], user2["uid"]], [user1, user2])
    end

    should "show host content update actions" do
      visit_edition @edition3
      click_on "History and notes"

      assert page.has_no_content?("Content block updated")
      assert page.has_no_content?("Email address updated")

      click_on "Edition 2"
      within "#version2" do
        within ".collapse.in" do
          within page.all(".action-content-block-update")[0] do
            assert page.has_content?(Time.zone.parse(@edition2_content_update_event_2["created_at"]).to_fs(:govuk_date))
            assert page.has_content?("Content block updated by User 1")
            assert page.has_content?("Email address updated")
          end

          within page.all(".action-content-block-update")[1] do
            assert page.has_content?(Time.zone.parse(@edition2_content_update_event_1["created_at"]).to_fs(:govuk_date))
            assert page.has_content?("Content block updated by User 2")
            assert page.has_content?("Email address updated")
          end
        end
      end

      click_on "Edition 1"
      within "#version1" do
        within ".collapse.in" do
          within ".action-content-block-update" do
            assert page.has_content?(Time.zone.parse(@edition1_content_update_event["created_at"]).to_fs(:govuk_date))
            assert page.has_content?("Content block updated by User 1")
            assert page.has_content?("Email address updated")
          end
        end
      end
    end
  end

  def some_time_passes
    travel_to rand(1.hour..1.week).from_now
  end

  def create_content_update_event(updated_by_user_uid:)
    {
      "created_at" => Time.zone.now.to_s,
      "payload" => {
        "source_block" => {
          "updated_by_user_uid" => updated_by_user_uid,
          "content_id" => SecureRandom.uuid,
          "title" => "Some content",
          "document_type" => "content_block_email_address",
        },
      },
    }
  end
end
