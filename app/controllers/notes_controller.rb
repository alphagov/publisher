class NotesController < InheritedResources::Base
  belongs_to :edition
  before_action :require_editor_permissions

  include PathsHelper

  def create
    comment = params[:note][:comment]
    type = params[:note][:type] || Action::NOTE

    if comment.blank? && type == Action::IMPORTANT_NOTE
      resolve_important_note
    elsif comment.blank?
      flash[:warning] = "Didn’t save empty note"
      redirect_to history_add_edition_note_edition_path(resource)
    elsif current_user.record_note(resource, comment, type)
      flash[:success] = "Note recorded"
      redirect_to history_edition_path(parent)
    else
      flash[:danger] = "Note failed to save"
      redirect_to type == Action::IMPORTANT_NOTE ? history_update_important_note_edition_path(resource) : history_add_edition_note_edition_path(resource)
    end
  end

  def resource
    parent
  end

private

  def resolve_important_note
    if parent.important_note.present?
      current_user.resolve_important_note(parent)
      flash[:success] = "Note resolved"
    end
    redirect_to history_edition_path(parent)
  end
end
