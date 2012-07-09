class Admin::BaseController < InheritedResources::Base
  before_filter :authenticate_user!
  before_filter :require_signin_permission!
  defaults :route_prefix => 'admin'

  rescue_from Mongoid::Errors::DocumentNotFound, :with => :record_not_found

  def index
    redirect_to admin_root_url
  end

  def admin_template_folder_for(publication)
    tmpl_folder = publication.class.to_s.underscore.pluralize.downcase.gsub('_edition', '')
    "app/views/admin/#{tmpl_folder}"
  end

  def setup_view_paths_for(publication)
    prepend_view_path "app/views/admin/editions"
    prepend_view_path admin_template_folder_for(publication)
  end

  def record_not_found
    render :text => "404 Not Found", :status => 404
  end

  def description(r)
    r.format.underscore.humanize
  end
end
