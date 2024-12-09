class ContentItemController < ApplicationController
  def by_content_id
    artefact =
      Artefact.find_by(content_id: params[:content_id])

    if artefact
      redirect_url = if Flipflop.enabled?("design_system_publications_filter".to_sym)
                       "/?title_filter=#{artefact.latest_edition.title}&assignee_filter=&content_type_filter=all&states_filter%5B%5D=draft&states_filter%5B%5D=in_review&states_filter%5B%5D=amends_needed&states_filter%5B%5D=fact_check&states_filter%5B%5D=fact_check_received&states_filter%5B%5D=ready&states_filter%5B%5D=scheduled_for_publishing&states_filter%5B%5D=published"
                     else
                       "/?list=published&string_filter=#{artefact.latest_edition.slug}&user_filter=all"
                     end
      redirect_to redirect_url
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
