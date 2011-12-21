class Action
  include Mongoid::Document

  STATUS_ACTIONS = [
    CREATE              = "create",
    START_WORK          = "start_work",
    REQUEST_REVIEW      = "request_review",
    APPROVE_REVIEW      = "approve_review",
    APPROVE_FACT_CHECK  = "approve_fact_check",
    REQUEST_AMENDMENTS  = "request_amendments",
    SEND_FACT_CHECK     = "send_fact_check",
    RECEIVE_FACT_CHECK  = "receive_fact_check",
    PUBLISH             = "publish",
    ARCHIVE             = "archive",
    NEW_VERSION         = "new_version",
  ]

  NON_STATUS_ACTIONS = [
    NOTE                 = "note",
    ASSIGN               = "assign",
  ]

  embedded_in :whole_edition
  belongs_to :recipient, :class_name => "User"
  belongs_to :requester, :class_name => "User"

  field :approver_id,  :type => Integer
  field :approved,     :type => DateTime
  field :comment,      :type => String
  field :request_type, :type => String
  field :email_addresses, :type => String
  field :customised_message, :type => String
  field :created_at,   :type => DateTime, :default => lambda { Time.now }

  def container_class_name(edition)
    edition.container.class.name.underscore.humanize
  end

  def friendly_description
    case request_type
    when CREATE
      "Created #{edition.format}: \"#{edition.title}\" (by #{requester.name})"
    when START_WORK
      "Work started: \"#{edition.title}\" (#{edition.format}) by #{requester.name}"
    when REQUEST_REVIEW
      "Review requested: \"#{edition.title}\" (#{edition.format}) by #{requester.name}"
    when APPROVE_REVIEW
      "Okayed for publication: \"#{edition.title}\" (#{edition.format}) by #{requester.name}"
    when APPROVE_FACT_CHECK
      "Fact check okayed for publication: \"#{edition.title}\" (#{edition.format}) by #{requester.name}"
    when REQUEST_AMENDMENTS
      "Amends needed: \"#{edition.title}\" (#{edition.format}) by #{requester.name}"
    when SEND_FACT_CHECK
      "Fact check requested: \"#{edition.title}\" (#{edition.format}) by #{requester.name}"
    when RECEIVE_FACT_CHECK
      "Fact check response: \"#{edition.title}\" (#{edition.format})"
    when PUBLISH
      "Published: \"#{edition.title}\" (#{edition.format}) by #{requester.name}"
    when ARCHIVE
      "Archived: \"#{edition.title}\" (#{edition.format}) by #{requester.name}"
    when NEW_VERSION
      "New version: \"#{edition.title}\" (#{edition.format}) by #{requester.name}"
    when NOTE
      "Note added by #{requester.name}"
    when ASSIGN
      "Assigned: \"#{edition.title}\" (#{edition.format}) to #{recipient.name}"
    end
  end

  def status_action?
    STATUS_ACTIONS.include?(request_type)
  end

  def to_s
    request_type.humanize.capitalize
  end
<<<<<<< HEAD
  
  def is_fact_check_request?
    #SEND_FACT_CHECK is now a state - in older publications it isn't
    request_type == SEND_FACT_CHECK || request_type == 'fact_check_requested' ? true : false
=======

  def edition
    whole_edition
>>>>>>> Update admin presenter and action models and related tests. Most of these tests pass now
  end
end
