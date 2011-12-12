require 'api/generator'

class PublicationsController < ApplicationController
  caches_page :index
  respond_to :json, :html

  def show
    if section_name = Publication::SECTIONS.detect { |s| s.parameterize.to_s == params[:id] }
      data = show_section(section_name)
    else
      data = show_publication(params[:id], params[:edition], params[:snac])
    end

    if data
      respond_with(data)
    else
      head 404 and return
    end
  end

  def show_section(name)
    publications = Publication.where(section: name).collect(&:published_edition).compact
    publications = publications.to_a.collect do |g|
      {
        :title => g.title,
        :tags => g.container.tags,
        :slug => g.container.slug,
        :type => g.container.class.to_s.underscore
      }
    end

    return { :name => name, :type => 'section', :publications => publications }
  end

  def show_publication(slug, edition, snac)
    edition = Publication.find_and_identify_edition(slug, edition)
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
      render :json => details.to_json, :callback => params[:callback]
    else
      respond_with details
    end
  end
end
