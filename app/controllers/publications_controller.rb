require 'api/generator'

class PublicationsController < ApplicationController
  caches_page :index
  
  def show
    publication = Publication.first(conditions: {slug: params[:id]})
    head 404 and return if publication.nil?
    
    if params[:edition]
      # This is used for previewing yet-to-be-published editions. 
      # At some point this should require special authentication.
      edition = publication.editions.select { |e| e.version_number.to_i == params[:edition].to_i }.first
    else
      edition = publication.published_edition
    end
    head 404 and return if edition.nil?
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
