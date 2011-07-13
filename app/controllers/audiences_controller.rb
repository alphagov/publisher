class AudiencesController < ApplicationController
  def show
    @guides = Guide.any_in(audiences: [params[:id]]).collect(&:published_edition).compact
    render :json => @guides.collect do |g|
      {
        :title => g.title,
        :tags => g.tags,
        :url => admin_guide_url(g)
      }
    end
  end
end
