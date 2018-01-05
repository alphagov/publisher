class LinkCheckReportsController < ApplicationController
  before_filter :find_reportable

  def create

  end

private

  def find_reportable
    @reportable = Edition.find(params[:edition_id])
  end
end
