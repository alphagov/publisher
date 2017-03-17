class PublicationsController < InheritedResources::Base
  def show
    edition = Edition.find_or_create_from_panopticon_data(params[:id], current_user)

    if edition.persisted?
      UpdateWorker.perform_async(edition.id.to_s)
      redirect_with_return_to(edition) and return
    else
      render_new_form(edition) and return
    end
  end

  protected
    def redirect_with_return_to(edition)
      destination = "/editions/#{edition.id}"
      destination += '?return_to=' + params[:return_to] if params[:return_to]
      redirect_to destination
    end

    def render_new_form(edition)
      @publication = edition
      setup_view_paths_for(edition)
      render template: 'new'
    end
end
