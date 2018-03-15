require 'test_helper'

class DatesReportPresenterTest < ActiveSupport::TestCase
  should "provide a CSV export of content workflow" do
    publish_action = Action.new(
      request_type: "publish",
      created_at: "2015-04-30 09:16:03"
    )

    out_of_dates_action = Action.new(
      request_type: "publish",
      created_at: "2015-05-02 14:08:36"
    )

    create_action = Action.new(
      request_type: "create",
      created_at: "2015-05-02 14:08:36"
    )

    #edition published 1
    FactoryBot.create(:edition,
      title: "Cancel your visa, immigration or citizenship application",
      slug: "cancel-visa",
      state: "published",
      created_at: "2015-04-01 14:08:36",
      updated_at: "2015-04-02 14:08:36",
      actions: [publish_action])

    #edition published 2
    FactoryBot.create(:edition,
      title: "Family Visitor visa",
      slug: "family-visit-visa",
      state: "published",
      created_at:  "2015-04-29 16:16:03",
      updated_at:  "2015-04-29 16:16:03",
      actions: [publish_action])

    #edition archived
    FactoryBot.create(:edition,
      title: "The national curriculum",
      slug: "national-curriculum",
      state: "archived",
      created_at:  "2015-04-15 16:16:03",
      updated_at:  "2015-04-15 16:16:03",
      actions: [publish_action])

    #edition out of dates
    FactoryBot.create(:edition,
      title: "Family Visitor visa 2",
      slug: "family-visit-visa-2",
      state: "published",
      created_at:  "2015-04-15 16:16:03",
      updated_at:  "2015-04-15 16:16:03",
      actions: [out_of_dates_action])

    #edition not published
    FactoryBot.create(:edition,
      title: "Family Visitor visa 3",
      slug: "family-visit-visa-3",
      state: "ready",
      created_at:  "2015-04-03 16:16:03",
      updated_at:  "2015-04-03 16:16:03",
      actions: [create_action])

    csv = DatesReportPresenter.new(Date.parse("2015-04-01"), Date.parse("2015-04-30")).to_csv
    data = CSV.parse(csv, headers: true)

    assert_equal 3, data.length
    assert_equal "Cancel your visa, immigration or citizenship application", data[0]["title"]
    assert_equal "#{Plek.current.website_root}/cancel-visa", data[0]["url"]
    assert_equal "2015-04-30 09:16:03", data[0]["created_at"]

    assert_equal "The national curriculum", data[1]["title"]
    assert_equal "#{Plek.current.website_root}/national-curriculum", data[1]["url"]
    assert_equal "2015-04-30 09:16:03", data[1]["created_at"]

    assert_equal "Family Visitor visa", data[2]["title"]
    assert_equal "#{Plek.current.website_root}/family-visit-visa", data[2]["url"]
    assert_equal "2015-04-30 09:16:03", data[2]["created_at"]
  end
end
