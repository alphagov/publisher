class LegacyNotesController < InheritedResources::Base
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
    else
      if current_user.record_note(resource, comment, type) # rubocop:disable Style/IfInsideElse
        flash[:success] = "Note recorded"
      else
        flash[:danger] = "Note failed to save"
      end
    end
    redirect_to history_edition_path(parent)
  end

  def resolve
    resolve_important_note
    redirect_to history_edition_path(parent)
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
  end
end
