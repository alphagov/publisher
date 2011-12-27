require 'api/generator'

class PublicationsController < ApplicationController
  respond_to :json

  def show
    Rails.logger.info("pubctrl: enter #{Time.now.to_f}")
    data = compose_publication(params[:id], params[:edition], params[:snac])

    if data
      respond_with(data)
    else
      head 404 and return
    end
  end

  protected
  def allow_preview?
    local_request?
  end

  def compose_publication(slug, edition_number, snac)
    Rails.logger.info("pubctrl: compose #{slug} #{edition_number}")
    edition_number = nil unless allow_preview?
    Rails.logger.info("pubctrl: finding publication edition #{Time.now.to_f}")
    edition = WholeEdition.find_and_identify_edition(slug, edition_number)
    Rails.logger.info("pubctrl: found edition #{Time.now.to_f}")
    return nil if edition.nil?

    options = {:snac => params[:snac], :all => params[:all]}.select { |k, v| v.present? }
    Rails.logger.info("pubctrl: generating hash #{Time.now.to_f}")
    result = Api::Generator.edition_to_hash(edition, options)
    Rails.logger.info("pubctr: exit compose #{Time.now.to_f}")
    result
  end
end