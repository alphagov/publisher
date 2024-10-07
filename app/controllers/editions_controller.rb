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
  before_action only: %i[progress admin update] do
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
  alias_method :admin, :show

  def update
    @resource.assign_attributes(permitted_params)

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

  def history
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

  def progress
    if progress_edition(resource, params[:edition][:activity].permit(:comment, :request_type, :publish_at))
      flash[:success] = @command.status_message
    else
      flash[:danger] = @command.status_message
    end
    redirect_to edition_path(resource)
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

  def permitted_params
    params.require(:edition).permit(%i[title overview in_beta body major_change change_note])
  end
end
