class Admin::PublicationsController < Admin::BaseController
  def show
    edition = Edition.create_from_panopticon_data(params[:id], current_user, PANOPTICON_API_CREDENTIALS)

    if edition.persisted?
      redirect_with_return_to(edition) and return
    else
      render_new_form(edition) and return
    end
  end

  protected
    def redirect_with_return_to(edition)
      destination = "/admin/editions/#{edition.id}"
      destination += '?return_to=' + params[:return_to] if params[:return_to]
      redirect_to destination
    end

    def render_new_form(edition)
      @publication = edition
      setup_view_paths_for(edition)
      render template: 'new'
    end
end
