require 'api/guide'

class GuidesController < ApplicationController
  def show
    publication = Publication.first(conditions: {slug: params[:id]})
    edition = publication.published_edition
    generator = case publication.class
      when Transaction then Api::Generator::Transaction
      when Guide then Api::Generator::Guide
      when Answer then Api::Generator::Guide
    end
            
    render :json => generator.edition_to_hash(edition)
  end
end
