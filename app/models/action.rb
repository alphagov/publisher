require_dependency "safe_html"

class Action
  include Mongoid::Document

  STATUS_ACTIONS = [
    CREATE                      = "create".freeze,
    REQUEST_REVIEW              = "request_review".freeze,
    APPROVE_REVIEW              = "approve_review".freeze,
    APPROVE_FACT_CHECK          = "approve_fact_check".freeze,
    REQUEST_AMENDMENTS          = "request_amendments".freeze,
    SEND_FACT_CHECK             = "send_fact_check".freeze,
    RECEIVE_FACT_CHECK          = "receive_fact_check".freeze,
    SKIP_FACT_CHECK             = "skip_fact_check".freeze,
    SCHEDULE_FOR_PUBLISHING     = "schedule_for_publishing".freeze,
    CANCEL_SCHEDULED_PUBLISHING = "cancel_scheduled_publishing".freeze,
    PUBLISH                     = "publish".freeze,
    ARCHIVE                     = "archive".freeze,
    NEW_VERSION                 = "new_version".freeze,
    PUBLISH_POPULAR_LINKS       = "publish_popular_links".freeze,
  ].freeze

  NON_STATUS_ACTIONS = [
    NOTE                 = "note".freeze,
    IMPORTANT_NOTE       = "important_note".freeze,
    IMPORTANT_NOTE_RESOLVED = "important_note_resolved".freeze,
    ASSIGN = "assign".freeze,
    RESEND_FACT_CHECK = "resend_fact_check".freeze,
  ].freeze

  embedded_in :edition

  # Temp-to-be-brought-back
  # Currently we are using recipient_id & requester_id as a field to store the id's
  # to bypass the issue of having a belongs_to between a postgres table and a mongo table
  # we will most likely bring back the belongs_to relationship once we move action table to postgres.

  # belongs_to :recipient, class_name: "User", optional: true
  # belongs_to :requester, class_name: "User", optional: true

  field :approver_id,        type: Integer
  field :approved,           type: DateTime
  field :comment,            type: String
  field :comment_sanitized,  type: Boolean, default: false
  field :request_type,       type: String
  field :request_details,    type: Hash, default: {}
  field :email_addresses,    type: String
  field :customised_message, type: String
  field :created_at,         type: DateTime, default: -> { Time.zone.now }

  # Temp-to-be-removed
  # This will be removed once we move action table to postgres, this temporarily
  # allows to support the belongs to relation between action and user
  field :recipient_id,       type: BSON::ObjectId
  field :requester_id,       type: BSON::ObjectId

  def container_class_name(edition)
    edition.container.class.name.underscore.humanize
  end

  def status_action?
    STATUS_ACTIONS.include?(request_type)
  end

  def to_s
    if request_type == SCHEDULE_FOR_PUBLISHING
      string = "Scheduled for publishing"
      string += " on #{request_details['scheduled_time'].in_time_zone('London').strftime('%d/%m/%Y %H:%M')}" if request_details["scheduled_time"].present?
      string
    else
      request_type.humanize.capitalize
    end
  end

  def is_fact_check_request?
    # SEND_FACT_CHECK is now a state - in older publications it isn't
    [SEND_FACT_CHECK, "fact_check_requested"].include?(request_type)
  end

  # Temp-to-be-removed
  # The method below are getters and setters for assigned_to that allows us to set the requester & requester_id and get recipient & recipient_id.
  # We are unable to use [belongs_to :recipient, class_name: "User", optional: true & belongs_to :requester, class_name: "User", optional: true] as the User table is
  # in postgres and using a combination of setter and getter methods with a recipient_id & requester_id field
  # to be able to achieve congruent result as having a belongs to while we are moving other table to postgres
  def recipient
    User.find(recipient_id) if recipient_id
  end

  def requester
    User.find(requester_id) if requester_id
  rescue StandardError
    nil
  end

  def recipient=(user)
    self.recipient_id = user.id
  end

  def requester=(user)
    self.requester_id = user.id
  end
end
