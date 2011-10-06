require 'test_helper'

class AnswerTest < ActiveSupport::TestCase

  test 'a new answer is lined up' do
    without_metadata_denormalisation(Answer) do
      g = Answer.new(:slug=>"childcare")
      assert g.lined_up
    end
  end

  test 'an answer is not lined up once edited' do
    without_metadata_denormalisation(Answer) do
      g = Answer.new :slug=>"childcare", :name=>"Something", :panopticon_id => 1234574
      g.save!
      e = g.editions.first
      e.body = "this and that"
      e.save!
      assert !g.lined_up
    end
  end

end
