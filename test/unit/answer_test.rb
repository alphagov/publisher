require 'test_helper'

class AnswerTest < ActiveSupport::TestCase

  test 'a new answer is lined up' do
    without_metadata_denormalisation(Answer) do
      g = Answer.new(:slug=>"childcare")
      assert g.lined_up
    end
  end

  test 'starting work on an answer removes it from lined up' do
    without_metadata_denormalisation(Answer) do
      g = Answer.new :slug=>"childcare", :name=>"Something", :panopticon_id => 1234574
      g.save!
      user = User.create(:name => "Ben")
      user.start_work(g.latest_edition)
      assert_equal false, g.has_lined_up?
    end
  end
end
