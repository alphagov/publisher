module WorkflowActor
  def record_action(edition, type, options={})
    type = Action.const_get(type.to_s.upcase)
    action = edition.new_action(self, type, options)
    messenger_topic = edition.state.to_s.downcase
    Messenger.instance.send messenger_topic, edition unless messenger_topic == "created"
    NoisyWorkflow.make_noise(action).deliver
  end

  def take_action(edition, action, details = {})
    apply_guards = respond_to?(:"can_#{action}?") ? __send__(:"can_#{action}?", edition) : true

    if apply_guards and transition = edition.send(action)
      record_action(edition, action, details)
      edition
    else
      false
    end
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

  %W[start_work request_review receive_fact_check request_amendments approve_review approve_fact_check publish].each do |method|
    define_method(method) do |edition, details = {}|
      take_action(edition, __method__, details)
    end
  end

  def can_approve_review?(edition)
    edition.latest_status_action.requester_id != self.id
  end
  alias :can_request_amendments? :can_approve_review?

  def assign(edition, recipient)
    edition.assigned_to_id = recipient.id
    # We're saving the edition here as the controller treats assignment as a special case.
    # The controller saves the publication, then updates assignment.
    edition.save!
    record_action edition, __method__, recipient: recipient
  end
end
