class ContentItemController < ApplicationController
  def by_content_id
    artefact = Artefact.find_by(content_id: params[:content_id])

    if artefact
      return redirect_to find_content_path(search_text: artefact.latest_edition.slug) if Flipflop.enabled?(:design_system_edit_phase_3b)

      redirect_to root_path(list: "published", string_filter: artefact.latest_edition.slug, user_filter: "all")
    else
      redirect_with_error
    end
  rescue StandardError
    redirect_with_error
  end

private

  def redirect_with_error
    flash[:danger] = "The requested content was not found"
    redirect_to(Flipflop.enabled?(:design_system_edit_phase_3b) ? find_content_path : root_path)
  end
end
