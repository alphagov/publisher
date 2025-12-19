require "test_helper"

class HostContentUpdateEvent::ActionTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  let(:content_id) { SecureRandom.uuid }

  let(:host_content_update_event) { FactoryBot.build(:host_content_update_event, document_type: "content_block_email_address", content_id:) }
  let(:action) { HostContentUpdateEvent::Action.new(host_content_update_event) }

  it "returns a duck-typed representation of an Action" do
    assert_equal action.request_type, HostContentUpdateEvent::Action::CONTENT_BLOCK_UPDATE
    assert_equal action.created_at, host_content_update_event.created_at
    assert_equal action.requester, host_content_update_event.author
    assert_equal action.to_s, "Content block updated"
    assert_equal action.comment, "Email address updated"
    assert_equal action.block_url, "#{Plek.external_url_for('content-block-manager')}/content-id/#{content_id}"
    assert_equal action.comment_sanitized, false
    assert_equal action.is_fact_check_request?, false
    assert_equal action.recipient_id, nil
  end
end
