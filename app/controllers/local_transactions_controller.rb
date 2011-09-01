require 'api/generator'

class LocalTransactionsController < ApplicationController
  respond_to :json

  def show
    publication = Publication.first(conditions: {slug: params[:id]})
    head 404 and return if publication.nil?

    edition = publication.published_edition
    render :json => Api::Generator.edition_to_hash(edition)
  end

  def all
    publication = Publication.first(conditions: {slug: params[:id]})
    head 404 and return if publication.nil?

    edition = publication.published_edition
    render :json => Api::Generator::LocalTransaction.edition_to_hash_with_data(edition)
  end

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

  def snac
    publication = Publication.first(conditions: {slug: params[:id]})
    head 404 and return if publication.nil?

    edition = publication.published_edition
    head 404 and return unless publication.verify_snac(params[:snac])

    render :json => Api::Generator.edition_to_hash(edition, params[:snac])
  end
end
