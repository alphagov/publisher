class Admin::PublicationsController < Admin::BaseController
  def show
    publication = Publication.where(panopticon_id: params[:id]).first
    publication = import_publication params[:id] unless publication.present?
    destination = '/admin/' + publication.class.name.tableize + '/' + publication.id.to_s
    destination += '?return_to=' + params[:return_to] if params[:return_to]
    redirect_to destination
  end

  def import_publication panopticon_id
    Publication.import panopticon_id, current_user
  end
end
