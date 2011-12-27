module WorkflowActor
  def record_action(edition, type, options={})
    type = Action.const_get(type.to_s.upcase)
    action = edition.new_action(self, type, options)
    messenger_topic = edition.state.to_s.downcase
    Messenger.instance.send messenger_topic, edition unless messenger_topic == "created"
    NoisyWorkflow.make_noise(action).deliver
  end

  def take_action(edition, action, details = {})
    edition.send(action)
    record_action edition, action, details
    edition
  end

  def record_note(edition, comment)
    edition.new_action(self, 'note', comment: comment)
  end

  def create_whole_edition(format, attributes = {})
    format = "#{format}_edition" unless format.to_s.match(/edition$/)
    publication_class = format.to_s.camelize.constantize
    item = publication_class.create(attributes)
    record_action(item, Action::CREATE) if item.persisted?
    item
  end

  def new_version(edition)
    return false unless edition.published?

    new_edition = edition.build_clone
    if new_edition
      record_action new_edition, Action::NEW_VERSION
      new_edition
    else
      false
    end
  end

  def start_work(edition)
    take_action(edition, __method__)
  end

  def send_fact_check(edition, details)
    return false if details[:email_addresses].blank?

    note_text = "\n\nResponses should be sent to: " + edition.fact_check_email_address
    if details[:comment].blank?
      details[:comment] = "Fact check requested" + note_text
    else
      details[:comment] += note_text
    end

    edition.send_fact_check
    record_action edition, __method__, details
    NoisyWorkflow.request_fact_check(edition, details).deliver
    edition
  end

  def request_review(edition, details)
    return false if edition.in_review?
    take_action(edition, __method__, details)
  end

  def receive_fact_check(edition, details)
    take_action(edition, __method__, details)
  end

  def request_amendments(edition, details)
    return false if edition.latest_status_action.requester_id == self.id and edition.state == 'in_review'
    take_action(edition, __method__, details)
  end

  def approve_review(edition, details)
    return false if edition.latest_status_action.requester_id == self.id
    take_action(edition, __method__, details)
  end

  def approve_fact_check(edition, details)
    take_action(edition, __method__, details)
  end

  def publish(edition, details)
    take_action(edition, __method__, details)
  end

  def can_request_review?(edition)
    most_recent_request = edition.most_recent_action { |a| a.request_type == Action::STATUS_ACTIONS[REQUEST_REVIEW]}
    edition.can_request_review? and (most_recent_request.nil? or most_recent_request.requester != self)
  end

  def assign(edition, recipient)
    edition.assigned_to_id = recipient.id
    # We're saving the edition here as the controller treats assignment as a special case.
    # The controller saves the publication, then updates assignment.
    edition.save!
    record_action edition, __method__, recipient: recipient
  end
end
