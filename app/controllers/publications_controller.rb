require 'api/generator'

class PublicationsController < ApplicationController
  caches_page :index
  
  def show
    publication = Publication.first(conditions: {slug: params[:id]})
    head 404 and return if publication.nil?
    
    edition = publication.published_edition
    render :json => Api::Generator.edition_to_hash(edition)
  end

  def index
    published_editions = Publication.published.collect(&:published_edition).compact
    details = published_editions.collect do |g|
      {
        :title => g.title,
        :tags => g.container.tags,
        :url => publication_front_end_path(g.container)
      }
    end
      
    render :json => details
  end

  protected
  # TODO - find a better way to do this. cf. Admin::GuidesHelper
  def publication_front_end_path(publication)
    if publication.is_a?(Place)
      "/places/#{publication.slug}"
    else
      "/#{publication.slug}"
    end
  end

end
