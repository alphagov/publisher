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
    edition = guide.editions.first
    email = NoisyWorkflow.request_fact_check edition, 'jys@ketlai.co.uk'
    assert_equal ["eds@alphagov.co.uk"], email.reply_to
    assert_match /\bid:#{edition.fact_check_id}\b/, email.subject
    assert_match /\bid:#{edition.fact_check_id}\b/, email.body
  end
end
