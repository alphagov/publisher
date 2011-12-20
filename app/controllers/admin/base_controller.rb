class Admin::BaseController < InheritedResources::Base
  before_filter :authenticate_user!
  defaults :route_prefix => 'admin'

  rescue_from Mongoid::Errors::DocumentNotFound, :with => :record_not_found

  def index
    redirect_to admin_root_url
  end

  def admin_template_folder_for(publication)
    tmpl_folder = publication.class.to_s.underscore.pluralize.downcase.gsub('_edition', '')
    "app/views/admin/#{tmpl_folder}"
  end

  def admin_local_transaction_editions_path(*args)
    admin_editions_path
  end

  def admin_local_transaction_edition_path(edition)
    admin_edition_path(edition)
  end

  def admin_guide_edition_url(edition)
    "/admin/guides/#{edition.to_param}"
  end
  helper_method :admin_guide_edition_url
  helper_method :admin_local_transaction_editions_path
  helper_method :admin_local_transaction_edition_path

  protected
    def record_not_found
      render :text => "404 Not Found", :status => 404
    end

    def description(r)
      r.class.to_s.gsub('Edition', '').underscore.humanize
    end
end
