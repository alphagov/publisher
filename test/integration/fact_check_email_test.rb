require 'integration_test_helper'

class FactCheckEmailTest < ActionDispatch::IntegrationTest
  def prepare_answer(random_name)
    setup_users

    panopticon_has_metadata(
      :id => 15328,
      :name => random_name,
      :slug => 'test-answer'
    )

    @answer = @author.create_whole_edition(:answer, :title => random_name, :slug => 'test-answer', :panopticon_id => 15328)
    @answer.body = 'Body text'
    @answer.save!

    @author.request_review(@answer.editions.first, {comment: ''})
    @reviewer.send_fact_check(@answer.editions.first, {comment: ''})
    return @answer
  end

  test "should pick up emails and update the relevant publication" do
    pending "a good way to stub Mail.all or provide a test IMAP/POP server"
    # answer = prepare_answer("some name")
    #
    # first_email = Mail.new do
    #   from    'mikel@test.lindsaar.net'
    #   to      "#{answer.editions.first.fact_check_email_address}"
    #   subject 'This is a fact check response'
    #   body    'I like it. Good work!'
    # end
    #
    # Mail.stubs(:all).yields { [first_email] }
    #
    # handler = FactCheckEmailHandler.new
    # assert handler.process
  end
end