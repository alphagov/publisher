require 'api/generator'

class LocalTransactionsController < ApplicationController
  def show
    publication = Publication.first(conditions: {slug: params[:id]})
    head 404 and return if publication.nil?
    
    edition = publication.published_edition
    render :json => Api::Generator.edition_to_hash(edition)
  end

  def snac
    publication = Publication.first(conditions: {slug: params[:id]})
    head 404 and return if publication.nil?

    edition = publication.published_edition
    head 404 and return unless edition.verify_snac(params[:snac])

    render :json => Api::Generator.edition_to_hash(edition, params[:snac])
  end
end
