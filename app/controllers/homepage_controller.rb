class HomepageController < ApplicationController
  layout "design_system"
  before_action :fetch_latest_popular_link

  def show
    render "homepage/popular_links/show"
  end

  def create
    @latest_popular_links = @latest_popular_links.create_draft_popular_links_from_last_record
    render "homepage/popular_links/show"
  end

private

  def fetch_latest_popular_link
    @latest_popular_links = PopularLinksEdition.last
  end
end
