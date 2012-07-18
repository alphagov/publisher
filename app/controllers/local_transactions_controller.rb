require 'api/generator'

class LocalTransactionsController < ApplicationController
  respond_to :json

  def verify_snac
    publication = Publication.where(slug: params[:id]).first
    head 404 and return if publication.nil?

    matching_code = params[:snac_codes].detect { |snac| publication.service_provided_by?(snac) }

    if matching_code
      render :json => { snac: matching_code }
    else
      render :text => '', :status => 422
    end
  end

  def find_by_snac
    local_authority = LocalAuthority.find_by_snac(params[:snac])
    head 404 and return if local_authority.nil?
    render :json => {
      name: local_authority.name,
      snac: local_authority.snac
    }
  end

  def find_by_council_name
    council = params[:name]
    local_authority = LocalAuthority.where(name: /^#{council}/i).first
    head 404 and return if local_authority.nil?
    render :json => {
      name: local_authority.name,
      snac: local_authority.snac
    }
  end
end
