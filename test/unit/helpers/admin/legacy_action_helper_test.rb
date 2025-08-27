require "test_helper"

class LegacyActionHelperTest < ActionView::TestCase
  test "it converts zendesk tickets to links" do
    expected_link = "https://govuk.zendesk.com/tickets/1234"
    texts = ["Zendesk ticket #1234", "zendesk 1234", "Zen 1234", "zen #1234", "zen#1234", "zen:1234", "zendesk: 1234"]

    texts.each do |text|
      assert_equal auto_link_zendesk_tickets(text), "<a href=\"#{expected_link}\">#{text}</a>"
    end

    assert_equal auto_link_zendesk_tickets("zendesk 1234. Next"), "<a href=\"#{expected_link}\">zendesk 1234</a>. Next"
    assert_equal auto_link_zendesk_tickets("something something zendesk 1234. Next"), "something something <a href=\"#{expected_link}\">zendesk 1234</a>. Next"
    assert_equal auto_link_zendesk_tickets("somezendesk 1234. Next"), "some<a href=\"#{expected_link}\">zendesk 1234</a>. Next"
  end

  test "it splits the newest reply from fact check response emails" do
    emails = [
      "reply\n-----Original Message-----\noriginal",
      "reply-----Original Message-----original",
      "reply\n________________________________\noriginal",
      "reply\nOn 20 October\nPaul wrote:\noriginal",
      "reply\nOn 20 October Paul wrote:\noriginal",
      "reply\nSent from my iPhone\noriginal",
      "reply\nSent from my BlackBerry\noriginal",
    ]

    emails.each do |text|
      unformatted_email = split_email_at_reply(text)
      assert_equal unformatted_email.length, 3
      assert_match(/reply/, unformatted_email.first)
      assert_match(/original/, unformatted_email.last)

      formatted_email = legacy_format_email_text(text)
      assert_equal formatted_email.length, 3
      assert_match(/reply/, formatted_email.first)
      assert_match(/Toggle earlier messages/, formatted_email.second)
      assert_match(/original/, formatted_email.last)
    end
  end

  test "it splits only the newest reply from fact check response emails" do
    emails = [
      "reply\n-----Original Message-----\noriginal\n-----Original Message-----\nolder",
      "reply-----Original Message-----original\n\nSent from my iPhone\nolder",
      "reply\n________________________________\noriginal\n-----Original Message-----\nolder",
    ]

    emails.each do |text|
      unformatted_email = split_email_at_reply(text)
      assert_equal unformatted_email.length, 3

      assert_match(/reply/, unformatted_email.first)
      assert_no_match(/original/, unformatted_email.first)
      assert_no_match(/older/, unformatted_email.first)

      assert_match(/original/, unformatted_email.last)
      assert_match(/older/, unformatted_email.last)
    end
  end

  test "#action_note supports host content update events" do
    host_content_update_event = FactoryBot.build(:host_content_update_event, document_type: "Something")
    action = host_content_update_event.to_action

    note = legacy_action_note(action)

    assert_match(/Something updated/, note)
    assert_match(/View in Content Block Manager/, note)
    assert_match(/#{action.block_url}/, note)
  end

  test "#edition_actions includes update_events" do
    edition = FactoryBot.create(:edition)

    edition_actions = [
      stub(:create_action_and_link_check_reports, request_type: Action::CREATE, created_at: Time.zone.now - 1.week),
      stub(:note_action, request_type: Action::NOTE, created_at: Time.zone.now - 2.days),
      stub(:sent_fact_check_action, request_type: Action::SEND_FACT_CHECK, created_at: Time.zone.now - 3.days),
      stub(:receive_fact_check_action, request_type: Action::RECEIVE_FACT_CHECK, created_at: Time.zone.now - 1.day),
      stub(:important_note_action, request_type: Action::IMPORTANT_NOTE, created_at: Time.zone.now - 1.week),
      stub(:important_note_resolved_action, request_type: Action::IMPORTANT_NOTE_RESOLVED, created_at: Time.zone.now - 1.week),
      stub(:publish_action, request_type: Action::PUBLISH, created_at: Time.zone.now - 12.hours),
    ]

    edition.stubs(:actions).returns(edition_actions)

    update_events = [
      stub("HostContentUpdateEvent", to_action: stub(:host_content_update_event_action, created_at: Time.zone.now - 2.hours)),
      stub("HostContentUpdateEvent", to_action: stub(:host_content_update_event_action, created_at: Time.zone.now - 3.hours)),
      stub("HostContentUpdateEvent", to_action: stub(:host_content_update_event_action, created_at: Time.zone.now)),
    ]

    update_events[0].stubs(:is_for_edition?).with(edition).returns(true)
    update_events[1].stubs(:is_for_edition?).with(edition).returns(true)
    update_events[2].stubs(:is_for_edition?).with(edition).returns(false)

    expected_actions = [
      update_events[0].to_action,
      update_events[1].to_action,
      edition_actions[6],
      edition_actions[3],
      edition_actions[1],
      edition_actions[2],
      edition_actions[0],
    ]

    result = edition_actions(edition, update_events)

    assert_equal expected_actions, result
  end
end
