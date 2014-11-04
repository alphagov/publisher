# encoding: utf-8
class NotesController < InheritedResources::Base
  belongs_to :edition

  include PathsHelper

  def create
    comment = params[:note][:comment]
    if comment.blank?
      flash[:warning] = "Didn’t save empty note"
    else
      type = params[:note][:type] || Action::NOTE
      if current_user.record_note(resource, comment, type)
        flash[:success] = "Note recorded"
      else
        flash[:danger] = "Note failed to save"
      end
    end
    redirect_to edit_edition_path(parent) + '#history'
  end

  def resource
    parent
  end
end
