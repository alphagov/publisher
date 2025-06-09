class ArtefactsController < ApplicationController
  before_action :require_editor_permission

  def new
    @artefact = Artefact.new(content_id: SecureRandom.uuid)
  end

  def create
    @artefact = Artefact.new
    if @artefact.update_as(current_user, creatable_params)
      redirect_to publication_path(@artefact)
    else
      render "new"
    end
  end

  def update
    artefact = Artefact.find(updatable_params[:id])
    if artefact.update_as(current_user, updatable_params)
      UpdateWorker.perform_async(artefact.latest_edition_id)
      show_success_message
    else
      flash[:danger] = artefact.errors.full_messages.join("\n")
    end

    redirect_to metadata_artefact_path(artefact)
  end

  helper_method :formats

private

  def show_success_message
    if Flipflop.enabled?("design_system_edit".to_sym)
      flash[:success] = "Metadata has successfully updated".html_safe
    else
      flash[:notice] = "Metadata updated"
    end
  end

  def formats
    Artefact::FORMATS_BY_DEFAULT_OWNING_APP["publisher"] - Artefact::RETIRED_FORMATS
  end

  def metadata_artefact_path(artefact)
    edition = Edition.where(panopticon_id: artefact.id).order_by(version_number: :desc).first
    metadata_edition_path(edition)
  end

  def creatable_params
    params.require(:artefact).permit(:content_id, :name, :slug, :kind, :owning_app, :language)
  end

  def updatable_params
    params.require(:artefact).permit(:id, :slug, :language)
  end

  def require_editor_permission
    return if current_user.govuk_editor?

    if params[:action] == "update"
      flash[:danger] = "You do not have correct editor permissions for this action."
      artefact = Artefact.find(params[:id])
      redirect_to edition_path(artefact.latest_edition)
    else
      flash[:danger] = "You do not have permission to see this page."
      redirect_to root_path
    end
  end
end
