require 'api/generator'

class PublicationsController < ApplicationController
  respond_to :json

  def show
    data = compose_publication(params[:id], params[:edition], params[:snac])

    if data
      respond_with(data)
    else
      head 404 and return
    end
  end

protected
  def compose_publication(slug, edition, snac)
    edition = Publication.find_and_identify_edition(slug, edition)
    return nil if edition.nil?

    options = {:snac => params[:snac], :all => params[:all] }.select { |k, v| v.present? }
    Api::Generator.edition_to_hash(edition, options)
  end
end
