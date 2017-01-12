class ArtefactsController < ApplicationController
  def new
    @artefact = Artefact.new(content_id: SecureRandom.uuid)
  end

  def create
    @artefact = Artefact.new
    if @artefact.update_attributes_as(current_user, creatable_params)
      redirect_to publication_path(@artefact)
    else
      render "new"
    end
  end

  def update
    artefact = Artefact.find(updatable_params[:id])
    if artefact.update_attributes_as(current_user, updatable_params)
      PublishingAPIUpdater.perform_async(artefact.latest_edition_id)
      flash[:notice] = "Metadata updated"
    else
      flash[:danger] = artefact.errors.full_messages.join("\n")
    end
    redirect_to metadata_artefact_path(artefact)
  end

  helper_method :formats

private

  def formats
    Artefact::FORMATS_BY_DEFAULT_OWNING_APP['publisher']
  end

  def metadata_artefact_path(artefact)
    edition = Edition.where(panopticon_id: artefact.id).order_by(version_number: :desc).first
    metadata_edition_path(edition)
  end

  def creatable_params
    params.require(:artefact).permit(:content_id, :name, :slug, :kind, :owning_app, :language)
  end

  def updatable_params
    params.require(:artefact).permit(:id, :slug)
  end
end
