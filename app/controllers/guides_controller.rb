require 'api/guide'

class GuidesController < ApplicationController
  def show
    guide = Guide.first(conditions: {slug: params[:id]})
    edition = guide.published_edition
    render :json => Api::Generator::Guide.edition_to_hash(edition)
  end
end
