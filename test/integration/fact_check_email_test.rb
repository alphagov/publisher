require 'integration_test_helper'

class FactCheckEmailTest < ActionDispatch::IntegrationTest

  test "should pick up an email and update the relevant publication" do
    answer = Factory.create(:answer_edition, :state => 'fact_check')

    first_email = Mail.new do
      from    'mikel@test.lindsaar.net'
      to      "#{answer.fact_check_email_address}"
      subject 'This is a fact check response'
      body    'I like it. Good work!'
    end

    Mail.stubs(:all).yields( first_email )

    assert answer.fact_check?

    handler = FactCheckEmailHandler.new
    handler.process

    answer.reload
    assert answer.fact_check_received?

    action = answer.actions.last
    assert_equal "I like it. Good work!", action.comment
    assert_equal "receive_fact_check", action.request_type
  end
end
