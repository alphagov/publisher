require 'api/guide'

class GuidesController < ApplicationController
  def show
    publication = Publication.first(conditions: {slug: params[:id]})
    edition = publication.published_edition
    render :json => Api::Generator::Guide.edition_to_hash(edition)
  end
end
