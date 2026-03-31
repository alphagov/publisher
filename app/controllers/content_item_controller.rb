class ContentItemController < ApplicationController
  def by_content_id
    artefact = Artefact.find_by(content_id: params[:content_id])

    if artefact
      redirect_to find_content_path(search_text: artefact.latest_edition.slug)
    else
      redirect_with_error
    end
  rescue StandardError
    redirect_with_error
  end

private

  def redirect_with_error
    flash[:danger] = "The requested content was not found"
    redirect_to find_content_path
  end
end
