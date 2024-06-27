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

  def edit
    render "homepage/popular_links/edit"
  end

  def update
    update_link_items
    flash[:success] = "Popular links draft saved.".html_safe
    redirect_to show_popular_links_path
  rescue StandardError
    render "homepage/popular_links/edit"
  end

  def publish
    publish_latest_popular_links
    render "homepage/popular_links/show"
  end

private

  def fetch_latest_popular_link
    @latest_popular_links = PopularLinksEdition.last
  end

  def update_link_items
    @latest_popular_links.link_items = remove_leading_and_trailing_url_spaces(params[:popular_links].values)
    @latest_popular_links.save!
  end

  def remove_leading_and_trailing_url_spaces(links)
    link_items = []
    links.each do |link|
      link[:url] = link[:url].strip
      link_items << link
    end
    link_items
  end

  def publish_latest_popular_links
    @latest_popular_links.publish_popular_links
  end
end
