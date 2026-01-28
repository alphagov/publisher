module PublicationsTableHelper
  def reviewer(publication, current_user)
    if publication.state == "in_review"
      if publication.reviewer.present?
        publication.reviewer
      elsif current_user != publication.assigned_to && current_user.has_editor_permissions?(publication)
        render partial: "root/claim_2i", locals: { publication:, current_user: }
      end
    end
  end

  def edition_number(publication)
    if %w[published archived].include?(publication.state) && publication.subsequent_siblings.first.present?
      sanitize("#{publication.version_number} - #{link_to("##{publication.subsequent_siblings.first.version_number} in #{publication.subsequent_siblings.first.state.humanize.downcase}", edition_path(publication.subsequent_siblings.first), class: 'link-inherit')}")
    else
      publication.version_number.to_s
    end
  end

  def format(publication)
    publication.format.underscore.humanize
  end

  def important_note(publication)
    publication.important_note.presence&.comment
  end

  def awaiting_review(publication)
    time_ago_in_words(publication.review_requested_at) if publication.state == "in_review"
  end

  def sent_out(publication)
    publication.last_fact_checked_at.to_date.to_fs(:govuk_date_short) if publication.state == "fact_check"
  end

  def scheduled(publication)
    publication.publish_at.presence&.to_fs(:govuk_date_short)
  end

  def published_by(publication)
    publication.publisher.presence
  end
end
