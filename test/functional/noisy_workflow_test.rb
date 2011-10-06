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
    email = NoisyWorkflow.request_fact_check edition, {:email_addresses => 'jys@ketlai.co.uk', :customised_message => "Blah"}
    assert_equal ["factcheck+test-#{guide.id}@alphagov.co.uk"], email.reply_to
  end
end
