require 'api/generator'

class PublicationsController < ApplicationController
  caches_page :index
  respond_to :json, :html
  
  def show
    section_name = Publication::SECTIONS.detect { |s| s.parameterize.to_s == params[:id] }
    audience_name = Publication::AUDIENCES.detect { |s| s.parameterize.to_s == params[:id] }
    
    if section_name
      data = show_collection('section', section_name) and return if section_name
    elsif audience_name
      data = show_collection('audience', audience_name) and return 
    else
      data = show_publication(params[:id], params[:edition], params[:snac])
    end
    
    respond_with data
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
        :url => guide_url(:id => g.container.slug, :format => :json),
        :type => g.class.underscore
      }
    end
    
    return { :name => name, :type => type, :publications => publications }
  end

  def show_publication(slug, edition, snac)
    publication = Publication.where(slug: slug).first
    head 404 and return if publication.nil?
    
    if edition
      # This is used for previewing yet-to-be-published editions. 
      # At some point this should require special authentication.
      edition = publication.editions.select { |e| e.version_number.to_i == edition.to_i }.first
    else
      edition = publication.published_edition
    end
    head 404 and return if edition.nil?

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
        :url => publication_front_end_path(g.container)
      }
    end
      
    respond_with details
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
