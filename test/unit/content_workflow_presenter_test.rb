# encoding: utf-8
require 'test_helper'

class ContentWorkflowPresenterTest < ActiveSupport::TestCase
  should "provide a CSV export of content workflow" do
    action_1 = Action.new(
      request_type: "create",
      created_at: "2016-01-07 17:41:57"
    )

    action_2 = Action.new(
      request_type: "request_review",
      created_at: "2016-01-11 10:21:00"
    )

    action_3 = Action.new(
      request_type: "send_fact_check",
      created_at: "2016-01-17 12:11:33"
    )

    action_4 = Action.new(
      request_type: "request_amendments",
      created_at: "2016-01-20 17:41:28"
    )

    action_5 = Action.new(
      request_type: "send_fact_check",
      created_at: "2016-03-07 17:31:44"
    )

    transaction_edition = TransactionEdition.new(
      title: "Register to vote (armed forces)",
      slug: "register-to-vote-armed-forces",
      state: "published",
      assignee: "Ray Khan",
      actions: [action_1, action_2, action_3, action_4, action_5]
    )

    guide_edition = GuideEdition.new(
      title: "The Queen's Awards for Enterprise",
      slug: "queens-awards-for-enterprise",
      state: "published",
      assignee: "Constance Cerf",
      actions: [action_1, action_2, action_3, action_4, action_5]
    )

    Edition.stubs(:published).returns([transaction_edition, guide_edition])

    csv = ContentWorkflowPresenter.new(Edition.published).to_csv
    data = CSV.parse(csv, headers: true)

    assert_equal 10, data.length
    assert_equal "Register to vote (armed forces)", data.first["Content title"]
    assert_equal "register-to-vote-armed-forces", data.first["Content slug"]
    assert_equal "#{Plek.current.website_root}/register-to-vote-armed-forces", data.first["Content URL"]
    assert_equal "published", data.first["Current status"]
    assert_equal "create", data.first["Stage"]
    assert_equal "Transaction", data.first["Format"]
    assert_equal "Ray Khan", data.first["Current assignee"]
    assert_equal "2016-01-07 17:41:57", data.first["Created at"]

    assert_equal "The Queen's Awards for Enterprise", data[7]["Content title"]
    assert_equal "queens-awards-for-enterprise", data[7]["Content slug"]
    assert_equal "#{Plek.current.website_root}/queens-awards-for-enterprise", data[7]["Content URL"]
    assert_equal "published", data[7]["Current status"]
    assert_equal "send_fact_check", data[7]["Stage"]
    assert_equal "Guide", data[7]["Format"]
    assert_equal "Constance Cerf", data[7]["Current assignee"]
    assert_equal "2016-01-17 12:11:33", data[7]["Created at"]
  end
end
