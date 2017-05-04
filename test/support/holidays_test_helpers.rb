require 'gds_api/test_helpers/calendars'

module HolidaysTestHelpers
  include GdsApi::TestHelpers::Calendars

  def stub_holidays_used_by_fact_check
    calendars_has_no_bank_holidays(in_division: 'england-and-wales')
  end
end
