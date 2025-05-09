require "legacy_integration_test_helper"

class FactCheckEmailTest < LegacyIntegrationTest
  def fact_check_mail_for(edition, attrs = {})
    message = Mail.new do
      from    attrs.fetch(:from,    "foo@example.com")
      to      attrs.fetch(:to,      edition && edition.fact_check_email_address)
      cc      attrs.fetch(:cc,      nil)
      bcc     attrs.fetch(:bcc,     nil)
      subject attrs.fetch(:subject, "This is a fact check response [#{edition.present? ? edition.id : ''}]")
      body    attrs.fetch(:body,    "I like it. Good work!")
    end

    # The Mail.all(:delete_after_find => true) call in FactCheckEmailHandler will set this
    # on all messages before yielding them
    message.mark_for_delete = true
    message
  end

  delegate :fact_check_config, to: :'Publisher::Application'

  def assert_correct_state(key, value, state)
    answer = FactoryBot.create(:answer_edition, state: "fact_check")
    message = fact_check_mail_for(answer)
    message[key] = value

    Mail.stubs(:all).yields(message)
    FactCheckEmailHandler.new(fact_check_config, stub.stubs(:set)).process

    answer.reload
    assert answer.public_send("#{state}?")
  end

  test "should ignore emails about editions that do not exist e.g. if they have been deleted'" do
    answer = FactoryBot.create(:answer_edition, state: "fact_check")

    message = fact_check_mail_for(answer)
    Mail.stubs(:all).yields(message)

    answer.destroy!

    handler = FactCheckEmailHandler.new(fact_check_config, stub.stubs(:set))
    handler.process

    assert message.is_marked_for_delete?
  end

  test "should pick up an email and add an action to the edition, and advance the state to 'fact_check_received'" do
    answer = FactoryBot.create(:answer_edition, state: "fact_check")

    message = fact_check_mail_for(answer)
    Mail.stubs(:all).yields(message)

    handler = FactCheckEmailHandler.new(fact_check_config, stub.stubs(:set))
    handler.process

    answer.reload
    assert answer.fact_check_received?

    action = answer.actions.last
    assert_equal "I like it. Good work!", action.comment
    assert_equal "receive_fact_check", action.request_type

    assert message.is_marked_for_delete?
  end

  test "should pick up an email and add an action to the edition, even if it's not in 'fact_check' state" do
    answer = FactoryBot.create(:answer_edition, state: "fact_check_received")

    Mail.stubs(:all).yields(fact_check_mail_for(answer))

    handler = FactCheckEmailHandler.new(fact_check_config, stub.stubs(:set))
    handler.process

    answer.reload
    assert answer.fact_check_received?

    action = answer.actions.last
    assert_equal "I like it. Good work!", action.comment
    assert_equal "receive_fact_check", action.request_type
  end

  test "should pick up multiple emails and update the relevant publications" do
    answer1 = FactoryBot.create(:answer_edition, state: "fact_check")
    answer2 = FactoryBot.create(
      :answer_edition,
      state: "in_review",
      review_requested_at: Time.zone.now,
    )

    Mail.stubs(:all).multiple_yields(
      fact_check_mail_for(answer1, body: "First Message"),
      fact_check_mail_for(answer2, body: "Second Message"),
      fact_check_mail_for(answer1, body: "Third Message"),
    )

    handler = FactCheckEmailHandler.new(fact_check_config, stub.stubs(:set))
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
    message = fact_check_mail_for(nil, to: "something@example.com")

    Mail.stubs(:all).yields(message)

    handler = FactCheckEmailHandler.new(fact_check_config, stub.stubs(:set))
    handler.process

    assert_not message.is_marked_for_delete?
  end

  test "should look for fact-check address cc or bcc fields" do
    edition_cc = FactoryBot.create(:answer_edition, state: "fact_check")
    # Test that it ignores irrelevant recipients
    message_cc = fact_check_mail_for(edition_cc, to: "something@example.com", cc: edition_cc.fact_check_email_address)

    edition_bcc = FactoryBot.create(:answer_edition, state: "fact_check")
    # Test that it doesn't fail on a nil recipient field
    message_bcc = fact_check_mail_for(edition_bcc, to: nil, bcc: edition_bcc.fact_check_email_address)

    Mail.stubs(:all).multiple_yields(message_cc, message_bcc)

    handler = FactCheckEmailHandler.new(fact_check_config, stub.stubs(:set))
    handler.process

    assert message_cc.is_marked_for_delete?
    assert message_bcc.is_marked_for_delete?
  end

  test "should look for fact-check subject field" do
    edition = FactoryBot.create(:answer_edition, state: "fact_check")
    message = fact_check_mail_for(edition, subject: "Fact Checked [#{edition.id}]")

    Mail.stubs(:all).yields(message)

    handler = FactCheckEmailHandler.new(fact_check_config, stub.stubs(:set))
    handler.process_message(message)
    assert message.is_marked_for_delete?
  end

  test "should look for fact-check body field" do
    edition = FactoryBot.create(:answer_edition, state: "fact_check")
    message = fact_check_mail_for(edition, subject: "Fact Checked", body: "[#{edition.id}]")

    Mail.stubs(:all).yields(message)

    handler = FactCheckEmailHandler.new(fact_check_config, stub.stubs(:set))

    handler.process_message(message)
    assert message.is_marked_for_delete?
  end

  test "should invoke the supplied block after each message" do
    answer1 = FactoryBot.create(:answer_edition, state: "fact_check")
    answer2 = FactoryBot.create(
      :answer_edition,
      state: "in_review",
      review_requested_at: Time.zone.now,
    )

    Mail.stubs(:all).multiple_yields(
      fact_check_mail_for(answer1, body: "First Message"),
      fact_check_mail_for(answer2, body: "Second Message"),
    )

    handler = FactCheckEmailHandler.new(fact_check_config, stub.stubs(:set))

    invocations = 0
    handler.process do
      invocations += 1
    end

    assert_equal 2, invocations
  end

  context "Out of office replies" do
    should "remain in Fact Check state if email is an out of office reply" do
      assert_correct_state("Auto-Submitted", "auto-replied", "fact_check")
    end

    should "progress to Fact Check Received state if email is a genuine reply" do
      assert_correct_state("X-Some-Header", "some-value", "fact_check_received")
    end
  end
end
