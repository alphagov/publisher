class HomepageController < ApplicationController
  layout "design_system"
  before_action :fetch_latest_popular_link
  before_action :require_homepage_editor_permissions

  include GDS::SSO::ControllerMethods

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
    @latest_popular_links.link_items = remove_leading_and_trailing_url_spaces(params[:popular_links].values)
    @latest_popular_links.save_draft

    flash[:success] = "Popular links draft saved.".html_safe
    redirect_to show_popular_links_path
  rescue StandardError
    render "homepage/popular_links/edit"
  end

  def publish
    @latest_popular_links.publish
    flash[:success] = "Popular links successfully published.".html_safe
    render "homepage/popular_links/show"
  end

private

  def fetch_latest_popular_link
    @latest_popular_links = PopularLinksEdition.last
  end

  def remove_leading_and_trailing_url_spaces(links)
    link_items = []
    links.each do |link|
      link[:url] = link[:url].strip
      link_items << link
    end
    link_items
  end

  def require_homepage_editor_permissions
    authorise_user!("homepage_editor")
  end
end
