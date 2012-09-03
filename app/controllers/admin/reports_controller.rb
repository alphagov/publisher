class Admin::ReportsController < ApplicationController
  ActionController::Renderers.add :csv do |detailed_report, options|
    headers['Cache-Control']             = 'must-revalidate, post-check=0, pre-check=0'
    headers['Content-Disposition']       = "attachment; filename=#{detailed_report.filename}.csv"
    headers['Content-Type']              = 'text/csv'
    headers['Content-Transfer-Encoding'] = 'binary'

    self.response_body = detailed_report.to_csv
  end

  before_filter :authenticate_user!

  def index
  end

  def progress
    report = EditorialProgressPresenter.new
    render csv: report
  end
end