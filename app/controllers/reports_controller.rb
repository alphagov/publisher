class ReportsController < ApplicationController
  layout "design_system"

  include ActionView::Helpers::TagHelper

  before_action :authenticate_user!

  def index; end

  def progress
    redirect_to Report.new("editorial_progress").url, allow_other_host: true
  end

  def organisation_content
    redirect_to Report.new("organisation_content").url, allow_other_host: true
  end

  def edition_churn
    redirect_to Report.new("edition_churn").url, allow_other_host: true
  end

  def all_edition_churn
    redirect_to Report.new("all_edition_churn").url, allow_other_host: true
  end

  def content_workflow
    redirect_to Report.new("content_workflow").url, allow_other_host: true
  end

  def recent_content_workflow
    redirect_to Report.new("recent_content_workflow").url, allow_other_host: true
  end

  def all_urls
    redirect_to Report.new("all_urls").url, allow_other_host: true
  end

private

  def report_last_updated(report_name)
    ::Report.new(report_name).last_updated
  end
  helper_method :report_last_updated

  def report_generated_time_message(report_name)
    last_updated = report_last_updated(report_name)
    if last_updated
      "Generated #{last_updated.strftime('%-l:%M%#p')}"
    else
      "Report currently unavailable"
    end
  end
  helper_method :report_generated_time_message
end
