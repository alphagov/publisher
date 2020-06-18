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
end
