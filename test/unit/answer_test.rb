require 'test_helper'

class AnswerTest < ActiveSupport::TestCase

  test 'a new answer is lined up' do
    g = Answer.new(:slug=>"childcare")
    assert g.has_lined_up?
  end

  test 'starting work on an answer removes it from lined up' do
    g = Answer.new(slug: "childcare", name: "Something", panopticon_id: 1234574)
    g.save!
    user = User.create(name: "Ben")
    user.start_work(g.latest_edition)
    assert_equal false, g.has_lined_up?
  end

  test "a new edition of an answer creates a diff when published" do
    without_metadata_denormalisation(Answer) do
      answer = Answer.new(:name => "How much wood would a woodchuck chuck if a woodchuck could chuck wood?", :slug=>"woodchuck")
      answer.save!

      user = User.create :name => 'Michael'

      edition_one = answer.editions.first
      edition_one.body = 'A woodchuck would chuck all the wood he could chuck if a woodchuck could chuck wood.'
      edition_one.save!

      edition_one.state = :ready
      user.publish edition_one, comment: "First edition"

      edition_two = edition_one.build_clone
      edition_two.save!
      edition_two.body = "A woodchuck would chuck all the wood he could chuck if a woodchuck could chuck wood.\nAlthough no more than 361 cubic centimetres per day."
      edition_two.state = :ready
      user.publish edition_two, comment: "Second edition"

      publish_action = edition_two.actions.where(request_type: "publish").last

      assert_equal "A woodchuck would chuck all the wood he could chuck if a woodchuck could chuck wood.{+\"\\nAlthough no more than 361 cubic centimetres per day.\"}", publish_action.diff
    end
  end
end
