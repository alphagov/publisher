class ApplicationController < ActionController::Base
  protect_from_forgery

  include GDS::SSO::ControllerMethods

  before_filter :authenticate_user!
  before_filter :require_signin_permission!

  rescue_from Mongoid::Errors::DocumentNotFound, :with => :record_not_found

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

  def squash_multiparameter_datetime_attributes(params, attribute_names)
    attribute_names.each do |attribute_name|
      datetime_params = params.select { |k, v| k.include? attribute_name }.values.map(&:to_i)
      params.delete_if { |k, v| k.include? attribute_name }

      params[attribute_name] = Time.zone.local(*datetime_params) if datetime_params.present?
    end
    params
  end

end
