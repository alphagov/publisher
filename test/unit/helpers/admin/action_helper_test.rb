require 'test_helper'

class ActionHelperTest < ActionView::TestCase
  test "it converts zendesk tickets to links" do
    expected_link = 'https://govuk.zendesk.com/tickets/1234'
    texts = ['Zendesk ticket #1234', 'zendesk 1234', 'Zen 1234', 'zen #1234', 'zen#1234', 'zen:1234', 'zendesk: 1234']

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
      "reply\nSent from my BlackBerry\noriginal"
    ]

    emails.each do |text|
      unformatted_email = split_email_at_reply(text)
      assert_equal unformatted_email.length, 3
      assert_match(/reply/, unformatted_email.first)
      assert_match(/original/, unformatted_email.last)
    end

    emails.each do |text|
      formatted_email = format_email_text(text)
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
      refute_match(/original/, unformatted_email.first)
      refute_match(/older/, unformatted_email.first)

      assert_match(/original/, unformatted_email.last)
      assert_match(/older/, unformatted_email.last)
    end
  end
end
