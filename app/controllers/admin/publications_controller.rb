class Admin::PublicationsController < Admin::BaseController
  def show
    publication = Publication.where(panopticon_id: params[:id]).first

    unless publication.present?
      publication = Publication.import(params[:id], current_user)
      unless publication.save
        render_new_form(publication) and return
      end
    end
    
    destination = '/admin/' + publication.class.name.tableize + '/' + publication.id.to_s
    destination += '?return_to=' + params[:return_to] if params[:return_to]
    redirect_to destination
  end

  protected
    def render_new_form(publication)
      @publication = publication
      prepend_view_path "app/views/admin/publication_subclasses"
      prepend_view_path admin_template_folder_for(publication)
      render template: 'new'
    end
end
