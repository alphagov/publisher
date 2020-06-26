require "test_helper"

class FactCheckEmailHandlerTest < ActiveSupport::TestCase
  def handler
    FactCheckEmailHandler.new(Publisher::Application.fact_check_config)
  end

  test "#process_message returns true when email subject includes 'out of office'" do
    out_of_office_message = Mail.new { subject("Automatic reply: out of office") }
    other_message = Mail.new { subject("Any other subject") }

    assert handler.process_message(out_of_office_message)
    assert_not handler.process_message(other_message)
  end

  test "#process sends count of unprocessed emails to Graphite" do
    processed_message = Mail.new { subject("Automatic reply: out of office") }
    unprocessed_message = Mail.new { subject("Any other subject") }
    GovukStatsd.expects(:gauge).with("unprocessed_emails.count", 1)
    Mail.stubs(:all).multiple_yields(processed_message, unprocessed_message)

    handler.process
  end
end
