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
end
