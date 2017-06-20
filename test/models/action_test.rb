require "test_helper"

class ActionTest < ActiveSupport::TestCase
  test "#to_s should return the humanized version of the request type" do
    assert_equal "Approve review", Action.new(request_type: 'approve_review').to_s
  end

  test "#to_s should contain the scheduled time when request type is SCHEDULE_FOR_PUBLISHING" do
    assert_equal "Scheduled for publishing on 12/12/2014 00:00",
      Action.new(request_type: 'schedule_for_publishing',
                 request_details: { 'scheduled_time' => Date.parse('12/12/2014').to_time.utc }).to_s
  end
end
