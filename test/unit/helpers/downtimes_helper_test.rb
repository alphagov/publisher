require "test_helper"

class DowntimesHelperTest < ActionView::TestCase
  include DowntimesHelper

  def setup
    @next_year = 1.year.from_now.year
    @edition_live = FactoryBot.create(:transaction_edition)
    @edition_downtime = FactoryBot.create(:transaction_edition)
    @downtime = FactoryBot.create(
      :downtime,
      artefact: @edition_downtime.artefact,
      start_time: Time.zone.local(@next_year, 10, 10, 15),
      end_time: Time.zone.local(@next_year, 10, 11, 18),
    )
  end

  test "#downtime_datetime should be a short string representation start and end time" do
    downtime = FactoryBot.build(:downtime, start_time: Time.zone.local(@next_year, 10, 10, 15), end_time: Time.zone.local(@next_year, 10, 11, 18))
    assert_equal "3pm on 10 October to 6pm on 11 October", downtime_datetime(downtime)
  end

  test "#downtime_datetime should not repeat date if start and end times are on the same day" do
    downtime = FactoryBot.build(:downtime, start_time: Time.zone.local(@next_year, 10, 11, 15), end_time: Time.zone.local(@next_year, 10, 11, 18))
    assert_equal "3pm to 6pm on 11 October", downtime_datetime(downtime)
  end

  test "#downtime_datetime should not repeat date if downtime ends at midnight on next day" do
    downtime = FactoryBot.build(:downtime, start_time: Time.zone.local(@next_year, 10, 10, 21), end_time: Time.zone.local(@next_year, 10, 11, 0))
    assert_equal "9pm to midnight on 10 October", downtime_datetime(downtime)
  end

  test "#transactions_table_entries should create valid entries for table" do
    entries = transactions_table_entries([@edition_live, @edition_downtime])
    assert_equal entries, [
      [
        { text: @edition_live.title },
        { text: "Live" },
        { text: "<a class=\"govuk-link\" href=\"/editions/#{@edition_live.id}/downtime/new\">Add downtime</a>" },
        { text: "<a class=\"govuk-link\" href=\"#{Plek.website_root}/#{@edition_live.slug}\">View on website</a>" },
      ],
      [
        { text: @edition_downtime.title },
        { text: "Scheduled downtime 3pm on 10 October to 6pm on 11 October" },
        { text: "<a class=\"govuk-link\" href=\"/editions/#{@edition_downtime.id}/downtime/edit\">Edit downtime</a>" },
        { text: "<a class=\"govuk-link\" href=\"#{Plek.website_root}/#{@edition_downtime.slug}\">View on website</a>" },
      ],
    ]
  end
end
