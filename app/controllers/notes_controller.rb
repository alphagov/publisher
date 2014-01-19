class NotesController < InheritedResources::Base
  belongs_to :edition

  include PathsHelper

  def create
    if current_user.record_note(resource, params[:note][:comment])
      flash[:notice] = "Note recorded"
    else
      flash[:notice] = "Note failed to save"
    end
    redirect_to edit_edition_path(parent) + '#history'
  end

  def resource
    parent
  end
end
