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

  %W[local_transaction transaction place guide programme answer].each do |type|
    define_method("admin_#{type}_edition_path") do |edition|
      __send__("admin_#{type}_path", edition)
    end
    define_method("admin_#{type}_edition_url") do |edition|
      __send__("admin_#{type}_url", edition)
    end
    helper_method "admin_#{type}_edition_path".to_sym
    helper_method "admin_#{type}_edition_url".to_sym
  end

  def admin_local_transaction_editions_path(*args)
    admin_editions_path
  end

  protected
    def record_not_found
      render :text => "404 Not Found", :status => 404
    end

    def description(r)
      r.format.underscore.humanize
    end
end
