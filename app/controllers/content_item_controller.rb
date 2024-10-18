class ContentItemController < ApplicationController
  def by_content_id
    artefact =
      Artefact.find_by(content_id: params[:content_id])

    if artefact
      redirect_to edition_path(artefact.latest_edition)
    else
      redirect_to_root_path_with_error
    end
  rescue StandardError
    redirect_to_root_path_with_error
  end

private

  def redirect_to_root_path_with_error
    flash[:danger] = "The requested content was not found"
    redirect_to root_path
  end
end
