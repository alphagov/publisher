require 'api/generator'

class PublicationsController < ApplicationController
  respond_to :json
  before_filter :find_publication

  def show
    Rails.logger.info("pubctrl: enter #{Time.now.to_f}")
    data = compose_publication(params[:id], params[:edition], params[:snac])
    head 404 and return unless data

    data = compose_publication(params[:id], params[:edition], params[:snac])
    respond_with(data)
  end

  def verify_snac
    head 404 and return unless @edition
    matching_code = params[:snac_codes].detect { |snac| publication.verify_snac(snac) }

    if matching_code
      render :json => { snac: matching_code }
    else
      render :text => '', :status => 422
    end
  end

protected
  def allow_preview?
    local_request?
  end

  def find_publication
    edition_number = nil unless allow_preview?
    edition = WholeEdition.find_and_identify_edition(slug, edition_number)

    return nil if edition.nil?

    options = {:snac => params[:snac], :all => params[:all]}.select { |k, v| v.present? }
    result = Api::Generator.edition_to_hash(edition, options)
    result
    @edition = WholeEdition.find_and_identify(slug, edition_number)
  end

  def compose_publication(slug, edition_number, snac)
    options = {:snac => params[:snac], :all => params[:all] }.select { |k, v| v.present? }
    Api::Generator.edition_to_hash(@edition, options)
  end
end
