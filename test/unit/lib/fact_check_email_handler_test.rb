require "test_helper"
require "gmail_test_helper"

class FactCheckEmailHandlerTest < ActiveSupport::TestCase
  setup do
    @gauge = stub
  end

  def handler(messages)
    handler = FactCheckEmailHandler.new(Publisher::Application.fact_check_config, @gauge)
    stub_gmail_requirements(handler, messages)
    handler.stubs(:retrieve_message_list).returns(messages)
    handler.stubs(:retrieve_message_content).returns(*messages)
    handler
  end

  test "#process ignores 'out of office' emails" do
    subject = "Automatic reply: out of office"
    mail = Mail.new { subject(subject) }
    message = build_gmail_message(mail.to_s)

    @gauge.expects(:set).with(0)

    handler([message]).process

    assert message.label_ids.empty?
  end

  test "#process sends count of unprocessed emails to Prometheus" do
    out_of_office_mail = Mail.new { subject("Automatic reply: out of office") }
    out_of_office_message = build_gmail_message(out_of_office_mail.to_s)
    other_mail = Mail.new { subject("Any other subject") }
    other_message = build_gmail_message(other_mail.to_s)

    @gauge.expects(:set).with(1)

    handler = handler([out_of_office_message, other_message])
    handler.process
  end

  test "#process does not send count of unprocessed emails to Prometheus when emails cannot be retrieved" do
    Mail.stubs(:all).raises(StandardError)
    message = build_gmail_message

    local_handler = handler(message)
    local_handler.stubs(:authenticate).raises(StandardError)
    @gauge.expects(:set).never

    local_handler.process
  end

  test "#process does not process emails when in maintenance mode" do
    ClimateControl.modify(MAINTENANCE_MODE: "true") do
      handler = handler(message)
      handler.expects(:authenticate_gmail).never

      handler.process
    end
  end

  test "#process processes emails when maintenance mode is explicitly disabled" do
    ClimateControl.modify(MAINTENANCE_MODE: "false") do
      handler = handler(message)
      handler.expects(:authenticate_gmail).once

      handler.process
    end
  end
end
