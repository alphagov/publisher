require "test_helper"

class AllContentWorkflowPresenterTest < ActiveSupport::TestCase
  should "provide a CSV export of content workflow" do
    transaction_user = FactoryBot.create(:user, :govuk_editor, name: "Ray Khan")
    guide_user = FactoryBot.create(:user, :govuk_editor, name: "Constance Cerf")
    transaction_edition = FactoryBot.create(:transaction_edition, title: "Register to vote (armed forces)", slug: "register-to-vote-armed-forces", state: "published", assigned_to_id: transaction_user.id, actions:)
    guide_edition = FactoryBot.create(:guide_edition, title: "The Queen's Awards for Enterprise", slug: "queens-awards-for-enterprise", state: "published", assigned_to_id: guide_user.id, actions:)

    editions = [transaction_edition, guide_edition]

    csv = AllContentWorkflowPresenter.new(editions).to_csv
    data = CSV.parse(csv, headers: true)

    assert_equal 10, data.length
    assert_equal "Register to vote (armed forces)", data.first["Content title"]
    assert_equal "register-to-vote-armed-forces", data.first["Content slug"]
    assert_equal "#{Plek.website_root}/register-to-vote-armed-forces", data.first["Content URL"]
    assert_equal "published", data.first["Current status"]
    assert_equal "create", data.first["Stage"]
    assert_equal "Transaction", data.first["Format"]
    assert_equal "Ray Khan", data.first["Current assignee"]
    assert_equal "1", data.first["Version number"]
    assert_equal "2016-01-07 17:41:57", data.first["Created at"]
    assert_equal "2016-01-07", data.first["Date created"]
    assert_equal "17:41", data.first["Time created"]

    assert_equal "The Queen's Awards for Enterprise", data[7]["Content title"]
    assert_equal "queens-awards-for-enterprise", data[7]["Content slug"]
    assert_equal "#{Plek.website_root}/queens-awards-for-enterprise", data[7]["Content URL"]
    assert_equal "published", data[7]["Current status"]
    assert_equal "send_fact_check", data[7]["Stage"]
    assert_equal "Guide", data[7]["Format"]
    assert_equal "Constance Cerf", data[7]["Current assignee"]
    assert_equal "1", data[7]["Version number"]
    assert_equal "2016-01-17 12:11:33", data[7]["Created at"]
    assert_equal "2016-01-17", data[7]["Date created"]
    assert_equal "12:11", data[7]["Time created"]
  end

  def actions
    action1 = Action.new(
      request_type: "create",
      created_at: "2016-01-07 17:41:57",
    )

    action2 = Action.new(
      request_type: "request_review",
      created_at: "2016-01-11 10:21:00",
    )

    action3 = Action.new(
      request_type: "send_fact_check",
      created_at: "2016-01-17 12:11:33",
    )

    action4 = Action.new(
      request_type: "request_amendments",
      created_at: "2016-01-20 17:41:28",
    )

    action5 = Action.new(
      request_type: "send_fact_check",
      created_at: "2016-03-07 17:31:44",
    )

    [action1, action2, action3, action4, action5]
  end
end
