class DocumentsController < ApplicationController
  def by_content_id
    artefact =
      Artefact.find_by(content_id: params[:content_id])

    if artefact
      redirect_to edition_path(artefact.latest_edition)
    else
      flash[:error] = "The requested content was not found"
      redirect_to root_path
    end
  end
end
