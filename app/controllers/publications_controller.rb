class PublicationsController < InheritedResources::Base
  def show
    edition = Edition.find_or_create_from_panopticon_data(params[:id], current_user)

    if edition.persisted?
      UpdateWorker.perform_async(edition.id.to_s)
      redirect_with_return_to(edition)
    else
      render_new_form(edition)
    end
  end

protected

  def redirect_with_return_to(edition)
    redirect_to(
      controller: "editions",
      action: "show",
      id: edition.id,
      return_to: params.fetch(:return_to, nil)
    )
  end

  def render_new_form(edition)
    @publication = edition
    setup_view_paths_for(edition)
    render template: 'new'
  end
end
