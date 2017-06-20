require "test_helper"

class OverviewDashboardTest < ActiveSupport::TestCase

  test "Can create and retrieve dashboard overview objects" do
    overview = create_test_overview

    assert_equal overview.dashboard_type, "Format"
    assert_equal overview.result_group, "Guide"
    check_status_equal overview, row_status
  end

private
  def create_test_overview
    overview = OverviewDashboard.create dashboard_type: "Format", result_group: "Guide"

    row_status.each do |k, v|
      overview[k] = v
    end

    overview.save

    found_overviews = OverviewDashboard.where(dashboard_type:  "Format")
    assert_equal found_overviews.size, 1
    found_overviews.first
  end

  def row_status
    {
      draft: 1,
      ammends_needed: 1,
      in_review: 1,
      ready: 1,
      fact_check_recieved: 1,
      fact_check: 1,
      published: 1,
      archived: 1
    }
  end

  def check_status_equal(actual_object, expected_hash)
    expected_hash.each do |k, v|
      assert_equal actual_object[k], expected_hash[k]
    end
  end
end
