require 'api/guide'

class GuidesController < ApplicationController
  def show
    publication = Publication.first(conditions: {slug: params[:id]})
    head 404 if publication.nil?
    
    edition = publication.published_edition
    render :json => Api::Generator.edition_to_hash(edition)
  end
end
