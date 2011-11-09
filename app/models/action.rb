class Action
  include Mongoid::Document

  STATUS_ACTIONS = [
    CREATED              = "created",
    WORK_STARTED         = "work_started",
    NEW_VERSION          = "new_version",
    FACT_CHECK_REQUESTED = "fact_check_requested",
    FACT_CHECK_RECEIVED  = "fact_check_received",
    REVIEW_REQUESTED     = "review_requested",
    REVIEWED             = "reviewed",
    OKAYED               = "okayed",
    PUBLISHED            = "published",
  ]

  NON_STATUS_ACTIONS = [
    NOTE                 = "note",
    ASSIGNED             = "assigned",
  ]

  embedded_in :edition
  belongs_to :recipient, :class_name => "User"
  belongs_to :requester, :class_name => "User"

  field :approver_id,  :type => Integer
  field :approved,     :type => DateTime
  field :comment,      :type => String
  field :request_type, :type => String
  field :email_addresses, :type => String
  field :customised_message, :type => String
  field :created_at,   :type => DateTime, :default => lambda { Time.now }

  def friendly_description
    case request_type
    when CREATED
      "Created #{edition.container.class}: \"#{edition.title}\" (by #{requester.name})"
    when WORK_STARTED
      "Work started: \"#{edition.title}\" (#{edition.container.class}) by #{requester.name}"
    when NEW_VERSION
      "New version: \"#{edition.title}\" (#{edition.container.class}) by #{requester.name}"
    when FACT_CHECK_REQUESTED
      "Fact check requested: \"#{edition.title}\" (#{edition.container.class}) by #{requester.name}"
    when FACT_CHECK_RECEIVED
      "Fact check response: \"#{edition.title}\" (#{edition.container.class})"
    when REVIEW_REQUESTED
      "Review requested: \"#{edition.title}\" (#{edition.container.class}) by #{requester.name}"
    when REVIEWED
      "Amends needed: \"#{edition.title}\" (#{edition.container.class}) by #{requester.name}"
    when OKAYED
      "Okayed for publication: \"#{edition.title}\" (#{edition.container.class}) by #{requester.name}"
    when PUBLISHED
      "Published: \"#{edition.title}\" (#{edition.container.class}) by #{requester.name}"
    when NOTE
      "Note added by #{requester.name}"
    when ASSIGNED
      "Assigned: \"#{edition.title}\" (#{edition.container.class}) to #{recipient.name}"
    end
  end

  def status_action?
    STATUS_ACTIONS.include?(request_type)
  end

  def to_s
    request_type.humanize.capitalize
  end
end
