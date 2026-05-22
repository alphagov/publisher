require "test_helper"

class HostContentUpdateEvent::ActionTest < ActiveSupport::TestCase
  test "returns a duck-typed representation of an Action" do
    content_id = SecureRandom.uuid
    host_content_update_event = FactoryBot.build(:host_content_update_event, document_type: "content_block_email_address", content_id:)
    action = HostContentUpdateEvent::Action.new(host_content_update_event)

    assert_equal HostContentUpdateEvent::Action::CONTENT_BLOCK_UPDATE, action.request_type
    assert_equal host_content_update_event.created_at, action.created_at
    assert_equal host_content_update_event.author, action.requester
    assert_equal "Content block updated", action.to_s
    assert_equal "Email address updated", action.comment
    assert_equal "#{Plek.external_url_for('content-block-manager')}/content-id/#{content_id}", action.block_url
    assert_not action.comment_sanitized
    assert_not action.is_fact_check_request?
    assert_nil action.recipient_id
  end
end
