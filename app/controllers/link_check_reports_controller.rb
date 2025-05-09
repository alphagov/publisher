class LinkCheckReportsController < ApplicationController
  before_action :find_edition
  #come back to this - need to go in depth of link check repor changes
  def create
    service = LinkCheckReportCreator.new(
      edition: @edition,
    )

    @report = service.call

    respond_to do |format|
      format.js { render "link_check_reports/create" }
      format.html { redirect_to edition_url(@edition.id) }
    end
  end

  def show
    service = LinkCheckReportFinder.new(
      report_id: permitted_params[:id],
    )

    @report = service.call

    respond_to do |format|
      format.js { render "link_check_reports/show" }
      format.html { redirect_to edition_url(@edition.id) }
    end
  end

private

  def convert_to_bson_object_id(id)
    BSON::ObjectId.from_string(id)
  end

  def permitted_params
    params.permit(:edition_id, :id)
  end

  def find_edition
    @edition = Edition.find(params[:edition_id])
  end
end
