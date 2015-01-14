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

  def organisation_content
    documents = Artefact.where(owning_app: "publisher").not_in(state: ["archived"])
    render csv: OrganisationContentPresenter.new(documents)
  end

  private

  def facets
    facet_mappings = {}

    facet_classes = [
      BusinessSupport::BusinessSize,
      BusinessSupport::Location,
      BusinessSupport::Purpose,
      BusinessSupport::Sector,
      BusinessSupport::Stage,
      BusinessSupport::SupportType
    ]

    facet_classes.each do |facet_class|
      facet_class_key = facet_class.to_s.demodulize
      facet_mappings[facet_class_key] = {} unless facet_mappings.has_key?(facet_class_key)
      facet_class.all.each do |facet|
        facet_mappings[facet_class_key][facet.slug] = facet.name
      end
    end

    facet_mappings
  end
end
