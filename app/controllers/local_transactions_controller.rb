require 'api/generator'

class LocalTransactionsController < ApplicationController
  respond_to :json

  def verify_snac
    publication = Publication.first(conditions: {slug: params[:id]})
    head 404 and return if publication.nil?

    snac_codes = params[:snac_codes]
    verified_codes = snac_codes.collect do |snac|
      snac if publication.verify_snac(snac)
    end.compact
    if verified_codes.first
      render :json => {'snac' => verified_codes.first}
    else
      render :text => '', :status => 422
    end
  end

end
