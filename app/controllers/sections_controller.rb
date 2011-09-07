class SectionsController < ApplicationController
  respond_to :json
  
  def index
    respond_with Publication::SECTIONS
  end

  def show
    publications = Publication.where(section: [params[:id]]).collect(&:published_edition).compact
    details = publications.to_a.collect do |g|
      {
        :title => g.title,
        :tags => g.container.tags,
        :url => guide_url(:id => g.container.slug, :format => :json)
      }
    end
    
    respond_with details
  end
end
