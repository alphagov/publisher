require 'integration_test_helper'

class FactCheckEmailTest < ActionDispatch::IntegrationTest
  def fact_check_mail_for(edition, attrs = {})
    message = Mail.new do
      from    attrs[:from] || 'foo@example.com'
      to      attrs[:to] || edition.fact_check_email_address
      subject attrs[:subject] || "This is a fact check response"
      body    attrs[:body] || 'I like it. Good work!'
    end
    # The Mail.all(:delete_after_find => true) call in FactCheckEmailHandler will set this
    # on all messages before yielding them
    message.mark_for_delete= true
    message
  end

  test "should pick up an email and add an action to the edition, and advance the state to 'fact_check_received'" do
    answer = FactoryGirl.create(:answer_edition, :state => 'fact_check')

    message = fact_check_mail_for(answer)
    Mail.stubs(:all).yields( message )

    handler = FactCheckEmailHandler.new
    handler.process

    answer.reload
    assert answer.fact_check_received?

    action = answer.actions.last
    assert_equal "I like it. Good work!", action.comment
    assert_equal "receive_fact_check", action.request_type

    assert message.is_marked_for_delete?
  end

  test "should pick up an email and add an action to the edition, even if it's not in 'fact_check' state" do
    answer = FactoryGirl.create(:answer_edition, :state => 'fact_check_received')

    Mail.stubs(:all).yields( fact_check_mail_for(answer) )

    handler = FactCheckEmailHandler.new
    handler.process

    answer.reload
    assert answer.fact_check_received?

    action = answer.actions.last
    assert_equal "I like it. Good work!", action.comment
    assert_equal "receive_fact_check", action.request_type
  end

  test "should pick up multiple emails and update the relevant publications" do
    answer1 = FactoryGirl.create(:answer_edition, :state => 'fact_check')
    answer2 = FactoryGirl.create(:answer_edition, :state => 'in_review')

    Mail.stubs(:all).multiple_yields(
          fact_check_mail_for(answer1, :body => "First Message"),
          fact_check_mail_for(answer2, :body => "Second Message"),
          fact_check_mail_for(answer1, :body => "Third Message")
    )

    handler = FactCheckEmailHandler.new
    handler.process

    answer1.reload
    assert answer1.fact_check_received?
    answer2.reload
    assert answer2.in_review?

    action = answer1.actions[-2]
    assert_equal "First Message", action.comment
    assert_equal "receive_fact_check", action.request_type

    action = answer1.actions[-1]
    assert_equal "Third Message", action.comment
    assert_equal "receive_fact_check", action.request_type

    action = answer2.actions[-1]
    assert_equal "Second Message", action.comment
    assert_equal "receive_fact_check", action.request_type
  end

  test "should ignore and not delete messages with a non-expected recipient address" do

    message = fact_check_mail_for(nil, :to => "something@example.com")

    Mail.stubs(:all).yields(message)

    handler = FactCheckEmailHandler.new
    handler.process

    assert ! message.is_marked_for_delete?
  end

  test "should invoke the supplied block after each message" do
    answer1 = FactoryGirl.create(:answer_edition, :state => 'fact_check')
    answer2 = FactoryGirl.create(:answer_edition, :state => 'in_review')

    Mail.stubs(:all).multiple_yields(
          fact_check_mail_for(answer1, :body => "First Message"),
          fact_check_mail_for(answer2, :body => "Second Message")
    )

    handler = FactCheckEmailHandler.new

    invocations = 0
    handler.process do
      invocations += 1
    end

    assert_equal 2, invocations
  end
end
