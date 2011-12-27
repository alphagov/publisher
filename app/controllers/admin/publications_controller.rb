class Admin::PublicationsController < Admin::BaseController
  def show
    publication = WholeEdition.create_from_panopticon_data(params[:id], current_user)
    if publication.persisted?
      render_new_form(publication) and return
    else
      redirect_to(return_to_destination(publication)) and return
    end
  end

  protected
    def return_to_destination(publication)
      destination = "/admin/#{publication.class.name.tableize}/#{publication.id}"
      destination += '?return_to=' + params[:return_to] if params[:return_to]
      destination
    end

    def render_new_form(publication)
      @publication = publication
      setup_view_paths_for(publication)
      render template: 'new'
    end
end
