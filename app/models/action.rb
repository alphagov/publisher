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
      "#{edition.container.class} created by #{requester.name}"
    when WORK_STARTED
      "#{requester.name} started work on #{edition.container.class} '#{edition.title}'"
    when NEW_VERSION
      "New version \"#{edition.title}\" created by #{requester.name}"
    when FACT_CHECK_REQUESTED
      "A fact check for \"#{edition.title}\" was requested by #{requester.name}"
    when FACT_CHECK_RECEIVED
      "A fact check response for \"#{edition.title}\" has been received"
    when REVIEW_REQUESTED
      "A review and publish was requested by #{requester.name}"
    when REVIEWED
      "Reviewed by #{requester.name}. Not OK'd for publication"
    when OKAYED
      "OK'd for publication by #{requester.name}"
    when PUBLISHED
      "Published by #{requester.name}"
    when NOTE
      "#{requester.name} made a note"
    when ASSIGNED
      "#{requester.name} assigned \"#{edition.title}\" to #{recipient.name}"
    end
  end

  def status_action?
    STATUS_ACTIONS.include?(request_type)
  end

  def to_s
    request_type.humanize.capitalize
  end
end
