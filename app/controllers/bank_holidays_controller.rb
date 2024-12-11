# frozen_string_literal: true

class BankHolidaysController < ApplicationController
  layout "design_system"

  include GDS::SSO::ControllerMethods

  def show
    render "calendars/bank_holidays/show"
  end
end
