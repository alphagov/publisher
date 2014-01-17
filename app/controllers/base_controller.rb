class BaseController < InheritedResources::Base
  before_filter :authenticate_user!
  before_filter :require_signin_permission!

  rescue_from Mongoid::Errors::DocumentNotFound, :with => :record_not_found

  def index
    redirect_to root_url
  end

  def template_folder_for(publication)
    tmpl_folder = publication.class.to_s.underscore.pluralize.downcase.gsub('_edition', '')
    "app/views/#{tmpl_folder}"
  end

  def setup_view_paths_for(publication)
    prepend_view_path "app/views/editions"
    prepend_view_path template_folder_for(publication)
  end

  def record_not_found
    render :text => "404 Not Found", :status => 404
  end
end
