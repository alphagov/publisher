class Admin::PublicationsController < Admin::BaseController
  def show
    publication = WholeEdition.where(panopticon_id: params[:id]).first
    render_new_form(publication) and return unless publication.persisted?

    destination = '/admin/' + publication.class.name.tableize + '/' + publication.id.to_s
    destination += '?return_to=' + params[:return_to] if params[:return_to]
    redirect_to destination
  end

  protected
    def render_new_form(publication)
      @publication = publication
      setup_view_paths_for(publication)
      render template: 'new'
    end
end
