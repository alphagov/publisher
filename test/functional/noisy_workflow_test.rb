require 'test_helper'

class NoisyWorkflowTest < ActionMailer::TestCase
  tests NoisyWorkflow

  def template_guide
    g = Guide.new(:slug=>"childcare",:name=>"Something")
    edition = g.editions.first
    edition.title = 'One'
    g
  end
    
  test "fact checking" do
    guide = template_guide
    assert_equal ["eds@alphagov.co.uk"], NoisyWorkflow.request_fact_check(guide.editions.first, 'jys@ketlai.co.uk').reply_to
  end
end
