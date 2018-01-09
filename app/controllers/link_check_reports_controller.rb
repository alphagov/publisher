class LinkCheckReportsController < ApplicationController
  before_filter :find_edition

  def create
    service = LinkCheckReportCreator.new(
      edition: @edition
    )

    @report = service.call

    respond_to do |format|
      format.js { render 'link_check_reports/create' }
      format.html { redirect_to edition_url(@edition.id) }
    end
  end

private

  def find_edition
    @edition = Edition.find(params[:edition_id])
  end
end
