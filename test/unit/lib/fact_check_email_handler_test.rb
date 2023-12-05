require "test_helper"

class FactCheckEmailHandlerTest < ActiveSupport::TestCase
  def handler
    FactCheckEmailHandler.new(Publisher::Application.fact_check_config)
  end

  test "#process ignores 'out of office' emails" do
    out_of_office_message = Mail.new { subject("Automatic reply: out of office") }
    Mail.stubs(:all).yields(out_of_office_message)
    handler.process
    assert out_of_office_message.is_marked_for_delete?
  end

  test "#process sends count of unprocessed emails to Graphite" do
    processed_message = Mail.new { subject("Automatic reply: out of office") }
    unprocessed_message = Mail.new { subject("Any other subject") }
    GovukStatsd.expects(:gauge).with("unprocessed_emails.count", 1)
    Mail.stubs(:all).multiple_yields(processed_message, unprocessed_message)

    handler.process
  end

  test "#process does not send count of unprocessed emails to Graphite when emails cannot be retrieved" do
    Mail.stubs(:all).raises(StandardError)
    GovukStatsd.expects(:gauge).never

    handler.process
  end
end
