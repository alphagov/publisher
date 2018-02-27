class LinkCheckerApiController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  before_action :verify_signature

  rescue_from Mongoid::Errors::DocumentNotFound, with: :render_no_content

  def callback
    if link_check_report
      LinkCheckReportUpdater.new(
        report: link_check_report,
        payload: params
      ).call
    end

    render_no_content
  end

private

  def render_no_content
    head :no_content
  end

  def batch_id
    params.require(:id)
  end

  def edition
    @edition ||= Edition.find_by("link_check_reports.batch_id": batch_id)
  end

  def link_check_report
    @link_check_report ||= edition.link_check_reports.find_by(batch_id: batch_id)
  end

  def verify_signature
    return unless webhook_secret_token
    given_signature = request.headers["X-LinkCheckerApi-Signature"]
    return head :bad_request unless given_signature
    body = request.raw_post
    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), webhook_secret_token, body)
    head :bad_request unless Rack::Utils.secure_compare(signature, given_signature)
  end

  def webhook_secret_token
    Rails.application.secrets.link_checker_api_secret_token
  end
end
