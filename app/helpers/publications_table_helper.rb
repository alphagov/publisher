module PublicationsTableHelper
  # test written
  def reviewer(publication, current_user)
    if publication.state == "in_review"
      if publication.reviewer and publication.reviewer.present?
        publication.reviewer
      elsif current_user != publication.assigned_to && current_user.has_editor_permissions?(publication)
        render partial: "root/claim_2i", locals: {publication: publication, current_user: current_user}
      end
    end
  end

  # test written
  def edition_number(publication)
    if (publication.state == "published" || publication.state == "archived") && publication.subsequent_siblings.first.present?
      sanitize(publication.version_number.to_s + " - " + link_to("##{publication.subsequent_siblings.first.version_number} in #{publication.subsequent_siblings.first.state.humanize.downcase}", edition_path(publication.subsequent_siblings.first), class: 'link-inherit'))
    else
      publication.version_number.to_s
    end
  end

  # test written
  def format(publication)
    publication.format.underscore.humanize
  end

  # test written
  def important_note(publication)
    publication.important_note.comment if publication.important_note.present?
  end

  # test written
  def awaiting_review(publication)
    time_ago_in_words(publication.review_requested_at) if publication.state == 'in_review'
  end

  # test in progress
  def sent_out(publication)
    publication.last_fact_checked_at.to_date.to_fs(:govuk_date_short) if publication.state == 'fact_check'
  end

  # test written
  def scheduled(publication)
    publication.publish_at.to_fs(:govuk_date_short) if publication.publish_at.present?
  end

  # test written
  def published_by(publication)
    publication.publisher if publication.publisher.present?
  end
end
