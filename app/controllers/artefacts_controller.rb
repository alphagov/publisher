class ArtefactsController < ApplicationController
  layout "design_system"
  before_action :require_govuk_editor

  def new
    @artefact = Artefact.new
  end

  def content_details
    if params.dig(:artefact, :kind).blank?
      @artefact = Artefact.new
      @artefact.errors.add(:kind, "Select a content type")
      render :new
      return
    end

    @artefact = Artefact.new(kind: artefact_params[:kind])
  end

  def create
    @artefact = Artefact.new({ content_id: SecureRandom.uuid, owning_app: "publisher" })

    if @artefact.update_as(current_user, artefact_params)
      redirect_to publication_path(@artefact)
    else
      render "content_details"
    end
  end

private

  def artefact_params
    params.require(:artefact).permit(:name, :slug, :kind, :language)
  end
end
