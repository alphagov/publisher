class EditionsController < InheritedResources::Base
  include TabbedNavHelper
  layout "design_system"

  defaults resource_class: Edition, collection_name: "editions", instance_name: "resource"

  before_action :setup_view_paths, except: %i[index]
  before_action except: %i[index] do
    require_user_accessibility_to_edition(@resource)
  end
  before_action only: %i[unpublish confirm_unpublish process_unpublish] do
    require_govuk_editor(redirect_path: edition_path(resource))
  end
  before_action only: %i[update] do
    require_editor_permissions
  end

  helper_method :locale_to_language

  def index
    redirect_to root_path
  end

  def show
    @artefact = @resource.artefact

    render action: "show"
  end

  alias_method :metadata, :show
  alias_method :unpublish, :show

  def update
    assign_to = new_assignee
    params = permitted_params
    @resource.assign_attributes(params[:edition])
    success = @resource.update!

    if success == true
      update_assignment resource, assign_to

      UpdateWorker.perform_async(resource.id.to_s, update_action_is_publish?)
      flash[:success] = "Edition updated successfully."
    else
      @resource = resource
      @tagging_update = tagging_update_form
      @linkables = Tagging::Linkables.new
      @artefact = @resource.artefact
    end

    render action: "show"

    rescue StandardError => e
      Rails.logger.error "Error #{e.class} #{e.message}"
      render action: "show"
  end


  def history
    render action: "show"
  end

  def admin
    render action: "show"
  end

  def linking
    render action: "show"
  end

  def confirm_unpublish
    if redirect_url.blank? || validate_redirect(redirect_url)
      render "secondary_nav_tabs/confirm_unpublish"
    else
      error_message = "Redirect path is invalid. #{description(resource)} can not be unpublished."
      @resource.errors.add(:redirect_url, error_message)
      render "show"
    end
  end

  def process_unpublish
    artefact = @resource.artefact

    success = unpublish_edition(artefact)
    if success
      notice = "Content unpublished"
      notice << " and redirected" if redirect_url.present?
      flash[:success] = notice
      redirect_to root_path
    else
      render_confirm_page_with_error
    end
  rescue StandardError
    render_confirm_page_with_error
  end

protected

  def setup_view_paths
    setup_view_paths_for(resource)
  end

  def new_assignee
    assignee_id = (params[:edition] || {}).delete(:assigned_to_id)
    User.find(assignee_id) if assignee_id.present?
  end

  def update_assignment(edition, assignee)
    return if edition.assigned_to == assignee

    if !assignee
      current_user.unassign(edition)
    elsif assignee.has_editor_permissions?(resource)
      current_user.assign(edition, assignee)
    else
      flash[:danger] = "Chosen assignee does not have correct editor permissions."
    end
  end

  def update_action_is_publish?
    attempted_activity == :publish
  end

  def progress_edition(resource, activity_params)
    @command = EditionProgressor.new(resource, current_user)
    @command.progress(squash_multiparameter_datetime_attributes(activity_params.to_h, %w[publish_at]))
  end

  def attempted_activity
    Edition::ACTIONS.invert[params[:commit]]
  end

private

  def unpublish_edition(artefact)
    params["redirect_url"].strip.empty? ? UnpublishService.call(artefact, current_user) : UnpublishService.call(artefact, current_user, redirect_url)
  end

  def render_confirm_page_with_error
    @resource.errors.add(:unpublish, downstream_error_message)
    render "secondary_nav_tabs/confirm_unpublish"
  end

  def downstream_error_message
    "Due to a service problem, the edition couldn't be unpublished"
  end

  def setup_view_paths_for(publication)
    prepend_view_path "app/views/editions"
    prepend_view_path template_folder_for(publication)
  end

  def locale_to_language(locale)
    case locale
    when "en"
      "English"
    when "cy"
      "Welsh"
    else
      ""
    end
  end

  def validate_redirect(redirect_url)
    regex = /(\/([a-z0-9]+-)*[a-z0-9]+)+/
    redirect_url =~ regex
  end

  def make_govuk_url_relative(url = "")
    url.sub(%r{^(https?://)?(www\.)?gov\.uk/}, "/")
  end

  def redirect_url
    make_govuk_url_relative params["redirect_url"]
  end

  def description(resource)
    resource.format.underscore.humanize
  end

  def permitted_params
    params.permit(edition: %i[title overview in_beta body major_change change_note])
  end
end
