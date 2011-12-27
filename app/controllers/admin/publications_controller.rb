class Admin::PublicationsController < Admin::BaseController
  def show
    publication = WholeEdition.create_from_panopticon_data(params[:id], current_user)

    if publication.persisted?
      redirect_with_return_to(publication) and return
    else
      render_new_form(publication) and return
    end
  end

  protected
    def redirect_with_return_to(publication)
      destination = "/admin/#{publication.class.name.tableize}/#{publication.id}"
      destination += '?return_to=' + params[:return_to] if params[:return_to]
      redirect_to destination
    end

    def render_new_form(publication)
      @publication = publication
      setup_view_paths_for(publication)
      render template: 'new'
    end
end
