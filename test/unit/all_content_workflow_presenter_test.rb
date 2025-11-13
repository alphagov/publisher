require "test_helper"

class AllContentWorkflowPresenterTest < ActiveSupport::TestCase
  setup do
    @transaction_created_at_time = Time.zone.now - 2.days
    transaction_user = FactoryBot.create(:user, :govuk_editor, name: "Ray Khan")
    transaction_edition = FactoryBot.create(
      :transaction_edition,
      title: "Register to vote (armed forces)",
      slug: "register-to-vote-armed-forces",
      created_at: @transaction_created_at_time,
      state: "published",
      assigned_to_id: transaction_user.id,
    )

    @guide_created_at_time = Time.zone.now - 1.year
    guide_user = FactoryBot.create(:user, :govuk_editor, name: "Constance Cerf")
    guide_edition = FactoryBot.create(
      :guide_edition,
      title: "The Queen's Awards for Enterprise",
      slug: "queens-awards-for-enterprise",
      created_at: @guide_created_at_time,
      state: "published",
      assigned_to_id: guide_user.id,
    )

    action_time = @transaction_created_at_time
    [Action::CREATE, Action::REQUEST_REVIEW].each do |action_type|
      transaction_edition.actions.create!(
        request_type: action_type,
        created_at: action_time,
        requester_id: transaction_user.id,
        requester: transaction_user,
      )
      action_time += 1.hour
    end

    action_time = @guide_created_at_time
    [Action::SEND_FACT_CHECK, Action::REQUEST_AMENDMENTS].each do |action_type|
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
    csv = AllContentWorkflowPresenter.new(Edition.all.order(created_at: :desc).includes(:actions)).to_csv
    data = CSV.parse(csv, headers: true)

    assert_equal 4, data.length
    action_index = data.find_index { |row| row[5] == Action::CREATE }
    assert_equal "Register to vote (armed forces)", data[action_index]["Content title"]
    assert_equal @transaction_created_at_time.to_fs(:db), data[action_index]["Content created"]
    assert_equal "register-to-vote-armed-forces", data[action_index]["Content slug"]
    assert_equal "#{Plek.website_root}/register-to-vote-armed-forces", data[action_index]["Content URL"]
    assert_equal "published", data[action_index]["Current status"]
    assert_equal "create", data[action_index]["Stage"]
    assert_equal "Transaction", data[action_index]["Format"]
    assert_equal "Ray Khan", data[action_index]["Current assignee"]
    assert_equal @transaction_created_at_time.to_fs(:db), data[action_index]["Created at"]
    assert_equal "1", data[action_index]["Version number"]
    assert_equal @transaction_created_at_time.to_date.to_s, data[action_index]["Date created"]
    assert_equal @transaction_created_at_time.to_fs(:time), data[action_index]["Time created"]

    assert_not_nil(data.find_index { |row| row[5] == Action::REQUEST_REVIEW })
    assert_not_nil(data.find_index { |row| row[5] == Action::REQUEST_AMENDMENTS })

    action_index = data.find_index { |row| row[5] == Action::SEND_FACT_CHECK }
    assert_equal "The Queen's Awards for Enterprise", data[action_index]["Content title"]
    assert_equal @guide_created_at_time.to_fs(:db), data[action_index]["Content created"]
    assert_equal "queens-awards-for-enterprise", data[action_index]["Content slug"]
    assert_equal "#{Plek.website_root}/queens-awards-for-enterprise", data[action_index]["Content URL"]
    assert_equal "published", data[action_index]["Current status"]
    assert_equal "send_fact_check", data[action_index]["Stage"]
    assert_equal "Guide", data[action_index]["Format"]
    assert_equal "Constance Cerf", data[action_index]["Current assignee"]
    action_created_at_time = @guide_created_at_time
    assert_equal action_created_at_time.to_fs(:db), data[action_index]["Created at"]
    assert_equal "1", data[action_index]["Version number"]
    assert_equal action_created_at_time.to_date.to_s, data[action_index]["Date created"]
    assert_equal action_created_at_time.to_fs(:time), data[action_index]["Time created"]
  end
end
