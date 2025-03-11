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
  before_action only: %i[progress admin update confirm_destroy edit_assignee update_assignee request_amendments request_amendments_page no_changes_needed no_changes_needed_page] do
    require_editor_permissions
  end
  before_action only: %i[confirm_destroy destroy] do
    require_destroyable
  end

  before_action only: %i[edit_assignee update_assignee] do
    require_assignee_editable
  end

  helper_method :locale_to_language

  def index
    redirect_to root_path
  end

  def show
    @artefact = @resource.artefact
    render action: "show"
  end

  alias_method :admin, :show
  alias_method :metadata, :show
  alias_method :tagging, :show
  alias_method :unpublish, :show

  def request_amendments_page
    render "secondary_nav_tabs/request_amendments_page"
  end

  def no_changes_needed_page
    render "secondary_nav_tabs/no_changes_needed_page"
  end

  def duplicate
    command = EditionDuplicator.new(@resource, current_user)
    target_edition_class_name = "#{params[:to]}_edition".classify if params[:to]

    if !@resource.can_create_new_edition?
      flash[:warning] = "Another person has created a newer edition"
      redirect_to edition_path(resource)
    elsif command.duplicate(target_edition_class_name, current_user)
      new_edition = command.new_edition
      UpdateWorker.perform_async(new_edition.id.to_s)
      flash[:success] = "New edition created"
      redirect_to edition_path(new_edition)
    else
      flash[:danger] = command.error_message
      redirect_to edition_path(resource)
    end
  rescue StandardError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    @resource.errors.add(:show, "Due to a service problem, the edition couldn't be duplicated")
    render "show"
  end

  def update
    @resource.assign_attributes(permitted_update_params)

    if @resource.save
      UpdateWorker.perform_async(resource.id.to_s)
      flash.now[:success] = "Edition updated successfully."
    else
      @artefact = @resource.artefact
    end
  rescue StandardError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    @resource.errors.add(:show, "Due to a service problem, the edition couldn't be updated")
  ensure
    render "show"
  end

  def request_amendments
    if request_amendments_for_edition(@resource, params[:comment])
      flash.now[:success] = "2i amendments requested"
      render "show"
    else
      flash.now[:danger] = "Due to a service problem, the request could not be made"
      render "secondary_nav_tabs/request_amendments_page"
    end
  end

  def no_changes_needed
    if no_changes_needed_for_edition(@resource, params[:comment])
      flash.now[:success] = "2i approved"
      render "show"
    else
      flash.now[:danger] = "Due to a service problem, the request could not be made"
      render "secondary_nav_tabs/no_changes_needed_page"
    end
  end

  def history
    artefact = @resource.artefact
    @update_events = HostContentUpdateEvent.all_for_artefact(artefact) || []
    render action: "show"
  end

  def related_external_links
    render action: "show"
  end

  def update_related_external_links
    artefact = resource.artefact

    if params.key?("artefact")
      artefact.assign_attributes(permitted_external_links_params)

      if artefact.save
        flash[:success] = "Related links updated."
      else
        flash[:danger] = artefact.errors.full_messages.join("\n")
      end
    else
      flash[:danger] = "There aren't any external related links yet"
    end

    redirect_to related_external_links_edition_path(@resource.id)
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

  def progress
    if progress_edition(resource, params[:edition][:activity].permit(:comment, :request_type, :publish_at))
      flash[:success] = @command.status_message
    else
      flash[:danger] = @command.status_message
    end
    redirect_to edition_path(resource)
  end

  def confirm_destroy
    render "secondary_nav_tabs/confirm_destroy"
  end

  def add_edition_note
    render "secondary_nav_tabs/add_edition_note"
  end

  def update_important_note
    render "secondary_nav_tabs/update_important_note"
  end

  def destroy
    @resource.destroy!
    flash[:success] = "Edition deleted"
    redirect_to root_url
  rescue StandardError
    flash[:danger] = downstream_error_message(:deleted)
    render "secondary_nav_tabs/confirm_destroy"
  end

  def edit_assignee
    render "secondary_nav_tabs/_edit_assignee"
  end

  def update_assignee
    assignee_id = params.require(:assignee_id)

    if update_assignment(@resource, assignee_id)
      flash[:success] = "Assigned person updated."
      redirect_to edition_path
    else
      render "secondary_nav_tabs/_edit_assignee"
    end
  rescue ActionController::ParameterMissing
    flash.now[:danger] = "Please select a person to assign, or 'None' to unassign the currently assigned person."
    render "secondary_nav_tabs/_edit_assignee"
  rescue StandardError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    flash.now[:danger] = "Due to a service problem, the assigned person couldn't be saved"
    render "secondary_nav_tabs/_edit_assignee"
  end

protected

  def setup_view_paths
    setup_view_paths_for(resource)
  end

private

  def progress_edition(resource, activity_params)
    @command = EditionProgressor.new(resource, current_user)
    @command.progress(squash_multiparameter_datetime_attributes(activity_params.to_h, %w[publish_at]))
  end

  def request_amendments_for_edition(resource, comment)
    @command = EditionProgressor.new(resource, current_user)
    @command.progress({ request_type: "request_amendments", comment: comment })
  end

  def no_changes_needed_for_edition(resource, comment)
    @command = EditionProgressor.new(resource, current_user)
    @command.progress({ request_type: "approve_review", comment: comment })
  end

  def unpublish_edition(artefact)
    params["redirect_url"].strip.empty? ? UnpublishService.call(artefact, current_user) : UnpublishService.call(artefact, current_user, redirect_url)
  end

  def render_confirm_page_with_error
    @resource.errors.add(:unpublish, downstream_error_message(:unpublished))
    render "secondary_nav_tabs/confirm_unpublish"
  end

  def downstream_error_message(action)
    "Due to a service problem, the edition couldn't be #{action}"
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

  def progress_action_param
    params[:edition][:activity][:request_type]
  rescue StandardError
    nil
  end

  def permitted_update_params
    params.require(:edition).permit(%i[title overview in_beta body major_change change_note])
  end

  def permitted_external_links_params
    params.require(:artefact).permit(external_links_attributes: %i[title url id _destroy])
  end

  def require_destroyable
    return if @resource.can_destroy?

    flash[:danger] = "Cannot delete a #{description(@resource).downcase} that has ever been published."
    redirect_to edition_path(@resource)
  end

  def require_assignee_editable
    return if can_update_assignee?(@resource)

    flash[:danger] = "Cannot edit the assignee of an edition that has been published."
    redirect_to edition_path(@resource)
  end

  def update_assignment(edition, assignee_id)
    return true if assignee_id == edition.assigned_to_id

    if assignee_id == "none"
      current_user.unassign(edition)
      return true
    end

    assignee = User.where(id: assignee_id).first
    raise StandardError, "An attempt was made to assign non-existent user '#{assignee_id}' to edition '#{edition.id}'." unless assignee

    if assignee.has_editor_permissions?(@resource)
      current_user.assign(edition, assignee)
      return true
    end

    flash.now[:danger] = "Chosen assignee does not have correct editor permissions."
    false
  end
end
