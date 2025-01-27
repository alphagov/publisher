# frozen_string_literal: true

class BankHolidaysController < ApplicationController
  # Needed?
  include GDS::SSO::ControllerMethods
  layout "design_system"

  def create
    @latest_bank_holidays = @latest_bank_holidays.create_draft_bank_holidays_from_last_record
    render "calendars/bank_holidays/show"
  end

  def show
    render "calendars/bank_holidays/show"
  end
end
