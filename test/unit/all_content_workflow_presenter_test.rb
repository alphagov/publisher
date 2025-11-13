require "test_helper"

class AllContentWorkflowPresenterTest < ActiveSupport::TestCase
  setup do
    @transaction_created_at_time = Time.zone.now - 2.days
    transaction_user = FactoryBot.create(:user, :govuk_editor, name: "Ray Khan")
    transaction_edition = FactoryBot.create(:transaction_edition, title: "Register to vote (armed forces)",
                                                                  slug: "register-to-vote-armed-forces", created_at: @transaction_created_at_time,
                                                                  state: "published", assigned_to_id: transaction_user.id)
    @guide_created_at_time = Time.zone.now - 1.year
    guide_user = FactoryBot.create(:user, :govuk_editor, name: "Constance Cerf")
    guide_edition = FactoryBot.create(:guide_edition, title: "The Queen's Awards for Enterprise",
                                                      slug: "queens-awards-for-enterprise", created_at: @guide_created_at_time,
                                                      state: "published", assigned_to_id: guide_user.id)

    action_types = [
      Action::CREATE,
      Action::REQUEST_REVIEW,
      Action::SEND_FACT_CHECK,
      Action::REQUEST_AMENDMENTS,
      Action::SEND_FACT_CHECK,
    ]

    action_time = @transaction_created_at_time
    action_types.each do |action_type|
      transaction_edition.actions.create!(
        request_type: action_type,
        created_at: action_time,
        requester_id: transaction_user.id,
        requester: transaction_user,
      )
      action_time += 1.hour
    end

    action_time = @guide_created_at_time
    action_types.each do |action_type|
      guide_edition.actions.create!(
        request_type: action_type,
        created_at: action_time,
        requester_id: guide_user.id,
        requester: guide_user,
      )
      action_time += 1.day
    end
  end

  should "provide a CSV export of content workflow for the editions provided" do
    csv = AllContentWorkflowPresenter.new(Edition.all.order(created_at: :desc)).to_csv
    data = CSV.parse(csv, headers: true)

    assert_equal 10, data.length
    assert_equal "Register to vote (armed forces)", data[0]["Content title"]
    assert_equal "register-to-vote-armed-forces", data[0]["Content slug"]
    assert_equal "#{Plek.website_root}/register-to-vote-armed-forces", data[0]["Content URL"]
    assert_equal "published", data[0]["Current status"]
    assert_equal "create", data[0]["Stage"]
    assert_equal "Transaction", data[0]["Format"]
    assert_equal "Ray Khan", data[0]["Current assignee"]
    assert_equal @transaction_created_at_time.to_fs(:db), data[0]["Created at"]
    assert_equal "1", data[0]["Version number"]
    assert_equal @transaction_created_at_time.to_date.to_s, data[0]["Date created"]
    assert_equal @transaction_created_at_time.to_fs(:time), data[0]["Time created"]

    assert_equal "request_review", data[1]["Stage"]
    assert_equal "send_fact_check", data[2]["Stage"]
    assert_equal "request_amendments", data[3]["Stage"]

    assert_equal "The Queen's Awards for Enterprise", data[7]["Content title"]
    assert_equal "queens-awards-for-enterprise", data[7]["Content slug"]
    assert_equal "#{Plek.website_root}/queens-awards-for-enterprise", data[7]["Content URL"]
    assert_equal "published", data[7]["Current status"]
    assert_equal "send_fact_check", data[7]["Stage"]
    assert_equal "Guide", data[7]["Format"]
    assert_equal "Constance Cerf", data[7]["Current assignee"]

    action_created_at_time = @guide_created_at_time + 2.days
    assert_equal action_created_at_time.to_fs(:db), data[7]["Created at"]
    assert_equal "1", data[7]["Version number"]
    assert_equal action_created_at_time.to_date.to_s, data[7]["Date created"]
    assert_equal action_created_at_time.to_fs(:time), data[7]["Time created"]
  end
end
