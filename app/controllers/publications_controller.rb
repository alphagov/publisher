require 'api/generator'

class PublicationsController < ApplicationController
  caches_page :index
  respond_to :json, :html
  
  def show
    section_name = Publication::SECTIONS.detect { |s| s.parameterize.to_s == params[:id] }
    audience_name = Publication::AUDIENCES.detect { |s| s.parameterize.to_s == params[:id] }

    if section_name
      data = show_collection('section', section_name)
    elsif audience_name
      data = show_collection('audience', audience_name)
    else
      data = show_publication(params[:id], params[:edition], params[:snac])
    end
    
    if data
      respond_with(data)
    else
      head 404 and return
    end
  end

  def show_collection(type, name)
    if type == 'section'
      publications = Publication.where(section: name).collect(&:published_edition).compact
    else
      publications = Publication.any_in(audiences: [params[:id]]).collect(&:published_edition).compact
    end
      
    publications = publications.to_a.collect do |g|
      {
        :title => g.title,
        :tags => g.container.tags,
        :slug => g.container.slug,
        :type => g.class.to_s.underscore
      }
    end
    
    return { :name => name, :type => type, :publications => publications }
  end

  def show_publication(slug, edition, snac)
    publication = Publication.where(slug: slug).first
    return nil if publication.nil?
    
    if edition
      # This is used for previewing yet-to-be-published editions. 
      # At some point this should require special authentication.
      edition = publication.editions.select { |e| e.version_number.to_i == edition.to_i }.first
    else
      edition = publication.published_edition
    end
    return nil if edition.nil?

    options = {}
    allowed_options = [:snac,:all]
    allowed_options.each do |a|
      options[a] = params[a] if params[a]
    end

    Api::Generator.edition_to_hash(edition, options)
  end

  def index
    published_editions = Publication.published.collect(&:published_edition).compact
    details = published_editions.collect do |g|
      {
        :title => g.title,
        :tags => g.container.tags,
        :slug => g.container.slug
      }
    end
    if params[:callback]  
      render :json=> details.to_json, :callback => params[:callback]
    else
      respond_with details 
    end
  end
end
