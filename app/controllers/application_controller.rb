class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  layout "legacy_application"

  include GDS::SSO::ControllerMethods

  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from Notifications::Client::BadRequestError, with: :notify_bad_request

  def template_folder_for(publication)
    tmpl_folder = publication.editionable.class.to_s.underscore.pluralize.downcase.gsub("_edition", "")
    "app/views/#{tmpl_folder}"
  end

  def setup_view_paths_for(publication)
    prepend_view_path "app/views/editions"
    prepend_view_path template_folder_for(publication)
  end

  def record_not_found(exception)
    Rails.logger.warn "Error loading document: #{exception.message}"
    render body: { 'raw': "404 Not Found" }, status: :not_found
  end

  def squash_multiparameter_datetime_attributes(params, attribute_names)
    attribute_names.each do |attribute_name|
      datetime_params = params.select { |k, _| k.include? attribute_name }.to_h.sort.map { |_, v| v.to_i }
      params.delete_if { |k, _| k.include? attribute_name }
      params[attribute_name] = Time.zone.local(*datetime_params) if datetime_params.present?
    end
    params
  end

  def notify_bad_request(exception)
    # TODO: control this via the log level rather than an environment variable
    if %w[integration staging].include?(ENV["GOVUK_ENVIRONMENT"]) && exception.message =~ /team-only API key/
      # in production we care about all errors
      # in staging and integration the team-only error may be encountered by
      # end-users who should see a more helpful error message
      raise
    else
      error = <<~ERROR
        Error: One or more recipients not in GOV.UK Notify team (code: 400).
        This error will not occur in Production.
      ERROR

      render plain: error, status: :bad_request
    end
  end

  def require_govuk_editor(redirect_path: root_path)
    return if current_user.govuk_editor?

    flash[:danger] = "You do not have permission to see this page."
    redirect_to redirect_path
  end

  def require_editor_permissions
    return if current_user.has_editor_permissions?(resource)

    flash[:danger] = "You do not have correct editor permissions for this action."
    redirect_to edition_path(resource)
  end

  def require_user_accessibility_to_edition(edition)
    render html: "You do not have permission to access this page - please <a href='https://www.gov.uk/guidance/contact-the-government-digital-service/request-a-thing#change-govuk-content'>raise a content request</a> with GDS to get it updated.".html_safe, status: :not_found unless edition.is_accessible_to?(current_user)
  end
end
