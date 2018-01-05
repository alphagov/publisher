class LinkCheckReportCreator
  include Rails.application.routes.url_helpers

  CALLBACK_HOST = Plek.find("manuals-publisher")

  class InvalidReport < RuntimeError
    def initialize(original_error)
      @message = original_error.message
    end
  end

  def initialize(edition:)
    @edition = edition
  end

  def call
    return if uris.empty?

    link_report = call_link_checker_api.deep_symbolize_keys

    report = edition.link_check_reports.build(
      batch_id: link_report.fetch(:id),
      completed_at: link_report.fetch(:completed_at),
      status: link_report.fetch(:status),
      links: link_report.fetch(:links).map { |link| map_link_attrs(link) }
    )

    report.save!

    report
  rescue Mongoid::Errors::Validations => e
    raise InvalidReport.new(e)
  end

private

  attr_reader :edition

  def uris
    @uris ||= EditionLinkExtractor.new(edition: edition).call
  end

  def callback_url
    link_checker_api_callback_url(host: CALLBACK_HOST)
  end

  def call_link_checker_api
    Services.link_checker_api.create_batch(
      uris,
      webhook_uri: callback_url,
      webhook_secret_token: Rails.application.secrets.link_checker_api_secret_token
    )
  end

  def map_link_attrs(link)
    {
      uri: link.fetch(:uri),
      status: link.fetch(:status),
      checked_at: link.fetch(:checked),
      check_warnings: link.fetch(:warnings, []),
      check_errors: link.fetch(:errors, []),
      problem_summary: link.fetch(:problem_summary),
      suggested_fix: link.fetch(:suggested_fix)
    }
  end
end
