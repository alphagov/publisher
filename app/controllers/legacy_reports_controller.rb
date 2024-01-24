class LegacyReportsController < ApplicationController
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

  def all_content_workflow
    redirect_to Report.new("all_content_workflow").url, allow_other_host: true
  end

  def all_urls
    redirect_to Report.new("all_urls").url, allow_other_host: true
  end

private

  def report_last_updated(report_name)
    last_updated = ::Report.new(report_name).last_updated
    if last_updated
      tag.span "Generated #{last_updated.to_fs(:govuk_date)}", class: "text-muted"
    else
      tag.span "Report currently unavailable", class: "text-muted"
    end
  end
  helper_method :report_last_updated
end
