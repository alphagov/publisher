class HomepageController < ApplicationController
  layout "design_system"

  def show
    @latest_popular_links = PopularLinksEdition.last
    render "homepage/popular_links/show"
  end
end
