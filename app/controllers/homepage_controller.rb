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
    create_params = permitted_params
    @latest_popular_links.link_items = remove_leading_and_trailing_url_spaces(create_params[:popular_links].values)
    @latest_popular_links.save_draft
    flash[:success] = "Popular links draft saved.".html_safe
    redirect_to show_popular_links_path
  rescue GdsApi::HTTPErrorResponse
    flash[:danger] = publishing_api_save_error_message.html_safe
    render "homepage/popular_links/edit"
  rescue ActiveRecord::RecordInvalid
    render "homepage/popular_links/edit"
  rescue StandardError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    flash[:danger] = "Due to an application error, the edition couldn't be saved. #{try_again_message} #{raise_support_error_message}"
    render "homepage/popular_links/edit"
  end

  def publish
    @latest_popular_links.publish_latest

    flash[:success] = "Popular links successfully published.".html_safe
  rescue GdsApi::HTTPErrorResponse => e
    flash[:danger] = rescue_already_published_error(e)
  rescue StandardError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    flash[:danger] = "Due to an application error, the edition couldn't be published. #{try_again_message} #{raise_support_error_message}"
  ensure
    redirect_to show_popular_links_path
  end

  def destroy
    if @latest_popular_links.can_delete?
      @latest_popular_links.delete ? flash[:success] = "Popular links draft deleted.".html_safe : flash[:danger] = application_error_message
    else
      flash[:danger] = cannot_delete_published_error_message
    end
  rescue StandardError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    flash[:danger] = application_error_message
  ensure
    redirect_to show_popular_links_path
  end

  def confirm_destroy
    if @latest_popular_links.can_delete?
      render "homepage/popular_links/confirm_destroy"
    else
      flash[:danger] = cannot_delete_published_error_message
      redirect_to show_popular_links_path
    end
  end

private

  def permitted_params
    params.permit(popular_links: %i[title url])
  end

  def cannot_delete_published_error_message
    "Can't delete an already published edition. Please create a new edition to make changes.".html_safe
  end

  def application_error_message
    "Due to an application error, the draft couldn't be deleted. #{try_again_message} #{raise_support_error_message}".html_safe
  end

  def rescue_already_published_error(error)
    already_published_error?(JSON.parse(error.http_body)) ? "Popular links publish was unsuccessful, cannot publish an already published edition.".html_safe : publishing_api_publish_error_message
  end

  def already_published_error?(error_body)
    error_body["error"] && error_body["error"]["message"] && error_body["error"]["message"].include?("Cannot publish an already published")
  end

  def fetch_latest_popular_link
    @latest_popular_links = PopularLinksEdition.last
  end

  def publishing_api_publish_error_message
    "Popular links publish was unsuccessful due to a service problem. #{try_again_message}".html_safe
  end

  def publishing_api_save_error_message
    "Popular links save was unsuccessful due to a service problem. #{try_again_message}".html_safe
  end

  def try_again_message
    "Please wait for a few minutes and try again."
  end

  def remove_leading_and_trailing_url_spaces(links)
    link_items = []
    links.each do |link|
      link[:url] = link[:url].strip
      link_items << link.to_h
    end
    link_items
  end

  def raise_support_error_message
    "If the problem persists #{support_link}"
  end

  def support_link
    "<a href=\"#{Plek.external_url_for('support')}/technical_fault_report/new\">please raise a support ticket</a>"
  end

  def require_homepage_editor_permissions
    authorise_user!("homepage_editor")
  end
end
