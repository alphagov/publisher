module ImportantNoteHelper
  def important_notes(edition)
    edition.actions.reverse.select{|a| a.request_type == Action::IMPORTANT_NOTE }
  end

  def important_note_has_history?(edition)
    important_notes(edition).size > 1
  end
end
