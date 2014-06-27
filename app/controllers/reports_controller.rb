class ReportsController < ApplicationController
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
    report = EditorialProgressPresenter.new(Edition.not_in(state: ["archived"]))
    render csv: report
  end

  def business_support_schemes_content
    schemes = BusinessSupportEdition.published.asc("title")
    send_data BusinessSupportExportPresenter.new(schemes, facets).to_csv, :filename => 'business_support_schemes_content.csv'
  end

  private

    def facets
      slugs_and_names = {}

      facet_classes = [
        BusinessSupport::BusinessSize,
        BusinessSupport::Location,
        BusinessSupport::Purpose,
        BusinessSupport::Sector,
        BusinessSupport::Stage,
        BusinessSupport::SupportType
      ]

      facet_classes.each do |facet_class|
        facet_class.all.each do |facet|
          slugs_and_names[facet.slug] = facet.name
        end
      end

      slugs_and_names
    end
end
