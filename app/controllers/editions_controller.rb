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
  before_action only: %i[progress admin update confirm_destroy edit_assignee update_assignee edit_reviewer update_reviewer request_amendments request_amendments_page no_changes_needed no_changes_needed_page send_to_2i send_to_2i_page send_to_publish send_to_publish_page cancel_scheduled_publishing cancel_scheduled_publishing_page schedule schedule_page] do
    require_editor_permissions
  end
  before_action only: %i[confirm_destroy destroy] do
    require_destroyable
  end
  before_action only: %i[skip_review skip_review_page] do
    require_skip_review_permission
  end
  before_action only: %i[edit_assignee update_assignee] do
    require_assignee_editable
  end
  before_action only: %i[edit_reviewer update_reviewer] do
    require_reviewer_editable
  end
  before_action only: %i[schedule_page] do
    require_schedulable
  end

  helper_method :locale_to_language

  def index
    redirect_to root_path
  end

  def show
    @artefact = @resource.artefact
    @reviewer = User.where(id: @resource.reviewer).first
    render action: "show"
  end

  alias_method :admin, :show
  alias_method :metadata, :show
  alias_method :tagging, :show
  alias_method :unpublish, :show

  def request_amendments_page
    render "secondary_nav_tabs/request_amendments_page"
  end

  def send_to_2i_page
    render "secondary_nav_tabs/send_to_2i_page"
  end

  def no_changes_needed_page
    render "secondary_nav_tabs/no_changes_needed_page"
  end

  def skip_review_page
    render "secondary_nav_tabs/skip_review_page"
  end

  def schedule_page
    render "secondary_nav_tabs/schedule_page"
  end

  def send_to_publish_page
    render "secondary_nav_tabs/send_to_publish_page"
  end

  def cancel_scheduled_publishing_page
    render "secondary_nav_tabs/cancel_scheduled_publishing_page"
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
    if !@resource.can_request_amendments?
      flash.now[:danger] = "Edition is not in a state where amendments can be requested"
      render "secondary_nav_tabs/request_amendments_page"
    elsif request_amendments_for_edition(@resource, params[:comment])
      flash[:success] = "Amendments requested"
      redirect_to edition_path(resource)
    else
      flash.now[:danger] = "Due to a service problem, the request could not be made"
      render "secondary_nav_tabs/request_amendments_page"
    end
  end

  def no_changes_needed
    if !@resource.can_approve_review?
      flash.now[:danger] = "Edition is not in a state where a review can be approved"
      render "secondary_nav_tabs/no_changes_needed_page"
    elsif no_changes_needed_for_edition(@resource, params[:comment])
      flash[:success] = "2i approved"
      redirect_to edition_path(resource)
    else
      flash.now[:danger] = "Due to a service problem, the request could not be made"
      render "secondary_nav_tabs/no_changes_needed_page"
    end
  end

  def send_to_2i
    if !@resource.can_request_review?
      flash.now[:danger] = "Edition is not in a state where it can be sent to 2i"
      render "secondary_nav_tabs/send_to_2i_page"
    elsif send_to_2i_for_edition(@resource, params[:comment])
      flash[:success] = "Sent to 2i"
      redirect_to edition_path(resource)
    else
      flash.now[:danger] = "Due to a service problem, the request could not be made"
      render "secondary_nav_tabs/send_to_2i_page"
    end
  end

  def skip_review
    if !@resource.can_skip_review?
      flash.now[:danger] = "Edition is not in a state where review can be skipped"
      render "secondary_nav_tabs/skip_review_page"
    elsif skip_review_for_edition(@resource, params[:comment])
      flash[:success] = "2i review skipped"
      redirect_to edition_path(resource)
    else
      flash.now[:danger] = "Due to a service problem, the request could not be made"
      render "secondary_nav_tabs/skip_review_page"
    end
  end

  def schedule
    if !@resource.can_schedule_for_publishing?
      flash.now[:danger] = "Edition is not in a state where it can be scheduled for publishing"
      render "secondary_nav_tabs/schedule_page"
    elsif params[:publish_at_1i].empty? || params[:publish_at_2i].empty? || params[:publish_at_3i].empty? || params[:publish_at_4i].empty? || params[:publish_at_5i].empty?
      flash.now[:danger] = "Select a future time and/or date to schedule publication."
      render "secondary_nav_tabs/schedule_page"
    else
      publish_at = Time.zone.local(params[:publish_at_1i].to_i, params[:publish_at_2i].to_i, params[:publish_at_3i].to_i, params[:publish_at_4i].to_i, params[:publish_at_5i].to_i)

      if publish_at.present? && publish_at < Time.zone.now
        flash.now[:danger] = "Select a future time and/or date to schedule publication."
        render "secondary_nav_tabs/schedule_page"
      elsif schedule_for_edition(@resource, params[:comment], publish_at)
        flash[:success] = "Scheduled to publish at #{publish_at.to_fs(:govuk_date)}"
        redirect_to edition_path(resource)
      else
        flash.now[:danger] = "Due to a service problem, the request could not be made"
        render "secondary_nav_tabs/schedule_page"
      end
    end
  end

  def send_to_publish
    if !@resource.can_publish?
      flash.now[:danger] = "Edition is not in a state where it can be published"
      render "secondary_nav_tabs/send_to_publish_page"
    elsif send_to_publish_for_edition(@resource, params[:comment])
      flash[:success] = "Published"
      redirect_to edition_path(@resource)
    else
      flash.now[:danger] = "Due to a service problem, the request could not be made"
      render "secondary_nav_tabs/send_to_publish_page"
    end
  end

  def cancel_scheduled_publishing
    if !@resource.can_cancel_scheduled_publishing?
      flash.now[:danger] = "Edition is not in a state where scheduling can be cancelled"
      render "secondary_nav_tabs/cancel_scheduled_publishing_page"
    elsif cancel_scheduled_publishing_for_edition(@resource, params[:comment])
      flash[:success] = "Scheduling cancelled"
      redirect_to edition_path(@resource)
    else
      flash.now[:danger] = "Due to a service problem, the request could not be made"
      render "secondary_nav_tabs/cancel_scheduled_publishing_page"
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

  def diff
    @comparison = @resource.previous_siblings.last
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
    render "secondary_nav_tabs/edit_assignee_page"
  end

  def edit_reviewer
    render "secondary_nav_tabs/edit_reviewer_page"
  end

  def update_assignee
    assignee_id = params.require(:assignee_id)

    if update_assignment(@resource, assignee_id)
      flash[:success] = "Assigned person updated."
      redirect_to edition_path
    else
      render "secondary_nav_tabs/edit_assignee_page"
    end
  rescue ActionController::ParameterMissing
    flash.now[:danger] = "Select a person to assign"
    render "secondary_nav_tabs/edit_assignee_page"
  rescue StandardError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    flash.now[:danger] = "Due to a service problem, the assigned person couldn't be saved"
    render "secondary_nav_tabs/edit_assignee_page"
  end

  def update_reviewer
    reviewer_id = if params["reviewer_id"] == "none"
                    nil
                  else
                    params.require(:reviewer_id)
                  end

    @resource.assign_attributes(reviewer: reviewer_id)

    if @resource.save
      if @resource.reviewer == current_user.id.to_s
        flash[:success] = "You are now the 2i reviewer of this edition"
      elsif @resource.reviewer.nil?
        flash[:success] = "2i reviewer removed"
      else
        reviewer = User.where(id: @resource.reviewer).first
        flash[:success] = "#{reviewer} is now the 2i reviewer of this edition"
      end

      redirect_to edition_path
    else
      flash.now[:danger] = "The selected 2i reviewer could not be saved."
      render "secondary_nav_tabs/edit_reviewer_page"
    end
  rescue ActionController::ParameterMissing
    flash.now[:danger] = "Select a person to assign"
    render "secondary_nav_tabs/edit_reviewer_page"
  rescue StandardError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    flash.now[:danger] = "Due to a service problem, the reviewer couldn’t be saved."
    render "secondary_nav_tabs/edit_reviewer_page"
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

  def send_to_2i_for_edition(resource, comment)
    @command = EditionProgressor.new(resource, current_user)
    @command.progress({ request_type: "request_review", comment: comment })
  end

  def skip_review_for_edition(resource, comment)
    @command = EditionProgressor.new(resource, current_user)
    @command.progress({ request_type: "skip_review", comment: comment })
  end

  def schedule_for_edition(resource, comment, publish_at)
    @command = EditionProgressor.new(resource, current_user)
    @command.progress({ request_type: "schedule_for_publishing", comment: comment, publish_at: publish_at })
  end

  def send_to_publish_for_edition(resource, comment)
    @command = EditionProgressor.new(resource, current_user)
    publish_succeeded = @command.progress({ request_type: "publish", comment: comment })
    PublishWorker.perform_async(resource.id.to_s) if publish_succeeded
    publish_succeeded
  end

  def cancel_scheduled_publishing_for_edition(resource, comment)
    @command = EditionProgressor.new(resource, current_user)
    @command.progress({ request_type: "cancel_scheduled_publishing", comment: comment })
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

  def require_schedulable
    return if @resource.can_schedule_for_publishing?

    flash[:danger] = "Cannot schedule an edition that is not ready."
    redirect_to edition_path(@resource)
  end

  def require_assignee_editable
    return if can_update_assignee?(@resource)

    flash[:danger] = "Cannot edit the assignee of an edition that has been published."
    redirect_to edition_path(@resource)
  end

  def require_reviewer_editable
    return if can_update_reviewer?(@resource)

    flash[:danger] = "Cannot edit the reviewer of an edition that is not in review."
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

  def require_skip_review_permission
    return if current_user.skip_review?

    flash[:danger] = "You do not have correct editor permissions for this action."
    redirect_to edition_path(resource)
  end
end
