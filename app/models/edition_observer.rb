class EditionObserver < Mongoid::Observer
  class CannotDeletePublishedPublication < RuntimeError; end

  observe [:edition, :guide_edition, :licence_edition, :local_transaction_edition,
           :place_edition, :programme_edition, :transaction_edition, :answer_edition,
           :business_support_edition]

  def before_save(edition)
    create_action = edition.actions.where(:request_type.in => [Action::CREATE, Action::NEW_VERSION]).first
    publish_action = edition.actions.where(request_type: Action::PUBLISH).first
    archive_action = edition.actions.where(request_type: Action::ARCHIVE).first

    edition.assignee = edition.assigned_to.name if edition.assigned_to
    edition.creator = create_action.requester.name if create_action and create_action.requester
    edition.publisher = publish_action.requester.name if publish_action and publish_action.requester
    edition.archiver = archive_action.requester.name if archive_action and archive_action.requester

    return edition
  end

  def before_destroy(edition)
    raise CannotDeletePublishedPublication unless edition.can_destroy?
  end

  def after_create(edition)
    edition.siblings.update_all(sibling_in_progress: edition.version_number)
    return edition
  end

  def after_publish(edition, transition)
    edition.was_published
  end

  def after_request_amendments(edition, transition)
    edition.mark_as_rejected if !edition.rejected_count
  end
end
