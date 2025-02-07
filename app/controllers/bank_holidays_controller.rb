# frozen_string_literal: true

# TODO: Remove this after testing
require "gds_api/publishing_api"

class BankHolidaysController < ApplicationController
  # Needed?
  include GDS::SSO::ControllerMethods
  layout "design_system"

  # def create
    # @latest_bank_holidays = @latest_bank_holidays.create_draft_bank_holidays_from_last_record
    # render "calendars/bank_holidays/show"
  #  puts "Here"
  #     @latest_bank_holidays  = Services.publishing_api.get_content(BankHolidaysEdition.content_id, {})
  #     if @latest_bank_holidays.nil?
  #       puts "No bank holidays found"
  #     end
  # end

  def show
   # @editions_presenter = EditionsPresenter.new(BankHolidaysEdition.content_id)
   puts "Here"
   @latest_bank_holidays = BankHolidaysEdition.create_draft_bank_holidays_from_last_record
   puts "Here again"
  rescue Net::HTTPNotFound => e
    puts "Error #{e.class} #{e.message}"
  rescue StandardError => e
    puts "Error #{e.class} #{e.message}"
    render "calendars/bank_holidays/show"
  end
end
