require 'test_helper'

class AnswerTest < ActiveSupport::TestCase

  test 'a new answer is lined up' do
    g = AnswerEdition.new(slug: "childcare", panopticon_id: '123', title: 'My new answer')
    assert g.lined_up?
  end

  test 'starting work on an answer removes it from lined up' do
    g = AnswerEdition.new(slug: "childcare", panopticon_id: '123', title: 'My new answer')
    g.save!
    user = User.create(name: "Ben")
    user.start_work(g)
    assert_equal false, g.lined_up?
  end
end
