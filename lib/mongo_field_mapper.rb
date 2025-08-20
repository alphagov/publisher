# Maps fields from a source Mongo JSON object
# into the corresponding field in our ActiveRecord models
class MongoFieldMapper
  MAPPINGS = {
    Edition => {
      rename: {
        "_type" => "editionable_type",
      },
      process: {
        "_id" => ->(_obj, _key, value) { { "mongo_id" => value["$oid"] } },
        "panopticon_id" => ->(obj, _key, value) { { "panopticon_id" => obj.map_to_artifact_id(value) } },
        "assigned_to_id" => ->(obj, _key, value) { { "assigned_to_id" => obj.get_assigned_to_id(value) } },
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "publish_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "review_requested_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    LocalTransactionEdition => {
      process: {
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    CompletedTransactionEdition => {
      process: {
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    GuideEdition => {
      process: {
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    SimpleSmartAnswerEdition => {
      process: {
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    PlaceEdition => {
      process: {
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    AnswerEdition => {
      process: {
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    PopularLinksEdition => {
      process: {
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    TransactionEdition => {
      process: {
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    HelpPageEdition => {
      process: {
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    ProgrammeEdition => {
      process: {
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    VideoEdition => {
      process: {
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    LicenceEdition => {
      process: {
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    CampaignEdition => {
      process: {
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    Part => {
      process: {
        "_id" => ->(_obj, _key, value) { { "mongo_id" => value["$oid"] } },
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    Variant => {
      process: {
        "_id" => ->(_obj, _key, value) { { "mongo_id" => value["$oid"] } },
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    DevolvedAdministrationAvailability => {
      process: {
        "_id" => ->(_obj, _key, value) { { "mongo_id" => value["$oid"] } },
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    SimpleSmartAnswerEdition::Node => {
      process: {
        "_id" => ->(_obj, _key, value) { { "mongo_id" => value["$oid"] } },
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    SimpleSmartAnswerEdition::Node::Option => {
      process: {
        "_id" => ->(_obj, _key, value) { { "mongo_id" => value["$oid"] } },
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    User => {
      process: {
        "_id" => ->(_obj, _key, value) { { "mongo_id" => value["$oid"] } },
        "updated_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    Action => {
      process: {
        "_id" => ->(_obj, _key, value) { { "mongo_id" => value["$oid"] } },
        "recipient_id" => ->(obj, _key, value) { { "recipient_id" => obj.get_recipient_id(value) } },
        "request_details" => ->(_obj, _key, value) { { "request_details" => request_details(value) } },
        "requester_id" => ->(obj, _key, value) { { "requester_id" => obj.get_requester_id(value) } },
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    Artefact => {
      process: {
        "_id" => ->(_obj, _key, value) { { "mongo_id" => value["$oid"] } },
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "public_timestamp" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    ArtefactAction => {
      process: {
        "_id" => ->(_obj, _key, value) { { "mongo_id" => value["$oid"] } },
        "user_id" => ->(obj, _key, value) { { "user_id" => obj.get_artefact_action_user_id(value) } },
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    LocalService => {
      process: {
        "_id" => ->(_obj, _key, value) { { "mongo_id" => value["$oid"] } },
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    ArtefactExternalLink => {
      process: {
        "_id" => ->(_obj, _key, value) { { "mongo_id" => value["$oid"] } },
      },
    },
    OverviewDashboard => {
      process: {
        "_id" => ->(_obj, _key, value) { { "mongo_id" => value["$oid"] } },
      },
    },
    LinkCheckReport => {
      process: {
        "_id" => ->(_obj, _key, value) { { "mongo_id" => value["$oid"] } },
        "edition_id" => ->(obj, _key, value) { { "edition_id" => obj.get_link_check_report_edition_id(value) } },
        "updated_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "completed_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
    Link => {
      process: {
        "_id" => ->(_obj, _key, value) { { "mongo_id" => value["$oid"] } },
        "created_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
        "checked_at" => ->(_obj, key, value) { rails_timestamp(key, value) },
      },
    },
  }.freeze

  def initialize(model_class, log_file)
    @model_class = model_class
    @log_file = log_file
  end

  def active_record_attributes(obj)
    return obj.select { |k, _| keep_this_key?(k) } unless MAPPINGS[@model_class]

    attrs = {}
    obj.each do |key, value|
      mapped_attr = process(key, value)
      this_key = mapped_attr.keys.first
      attrs[this_key] = mapped_attr.values.first if this_key
    end
    attrs
  end

  # Mongo datetimes can be $date => '...' or $numberLong => '...'
  # or even in some cases $date => { $numberLong => (value) } }
  def self.unpack_datetime(value)
    if value.is_a?(Hash)
      # Recurse until you get something that isn't a Hash with one of these keys
      unpack_datetime(value["$date"] || value["$numberLong"].to_i / 1000)
    elsif !value
      nil
    elsif value.is_a?(Integer)
      # e.g. -473385600000
      Time.zone.at(value).iso8601
    else
      begin
        # e.g. "2019-06-21T11:52:37+00:00"
        Time.zone.parse(value).iso8601
        value
      rescue Date::Error
        # we also have some content with dates in the form {"$numberLong" => "(value)"}
        # in which case you can end up here with a value like "-473385600000" (quoted)
        Time.zone.at(value.to_i).iso8601
      end
    end
  end

  def self.request_details(value)
    request_detail = {}
    request_detail["scheduled_time"] = value["scheduled_time"]["$date"] if value.present?
    request_detail
  end

  def map_to_artifact_id(value)
    artefact = Artefact.where(mongo_id: value).last
    if artefact.nil?
      log "Error: artefact with mongo_id #{value} does not exist"
    end
    artefact.id
  end

  def get_assigned_to_id(value)
    return if value.nil?

    assigned_to_user = User.where(mongo_id: value["$oid"]).last
    if assigned_to_user.nil?
      log "Error: assigned to user with mongo_id #{value['$oid']} does not exist"
      return nil
    end
    assigned_to_user.id
  end

  def get_recipient_id(value)
    return if value.nil?

    recipient = User.where(mongo_id: value["$oid"]).last
    if recipient.nil?
      log "Error: recipient user with mongo_id #{value['$oid']} does not exist"
      return nil
    end
    recipient.id
  end

  def get_requester_id(value)
    return if value.nil?

    requester = User.where(mongo_id: value["$oid"]).last
    if requester.nil?
      log "Error: requester user with mongo_id #{value['$oid']} does not exist"
      return nil
    end
    requester.id
  end

  def get_artefact_action_user_id(value)
    return if value.nil?

    artefact_action_user = User.where(mongo_id: value["$oid"]).last
    if artefact_action_user.nil?
      log "Error: artefact action user with mongo_id #{value['$oid']} does not exist"
      return nil
    end
    artefact_action_user.id
  end

  def get_link_check_report_edition_id(value)
    link_check_report_edition = Edition.where(mongo_id: value["$oid"]).last
    if link_check_report_edition.nil?
      log "Error: edition with mongo_id #{value['$oid']} does not exist"
      raise LinkCheckReportEditionError, "Error: edition with mongo_id #{value['$oid']} does not exist"
    else
      link_check_report_edition.id
    end
  end

  # Return the given key with the unpacked date value if given,
  # otherwise return empty hash, to avoid conflicting with
  # the not-null constraint on Rails' timestamp keys
  def self.rails_timestamp(key, value)
    date = unpack_datetime(value)
    date ? { key => date } : {}
  end

  def process(key, value)
    if (proc = MAPPINGS[@model_class][:process][key])
      proc.call(self, key, value)
    else
      processed_key = target_key(key)
      keep_this_key?(processed_key) ? { processed_key => value } : {}
    end
  end

  def keep_this_key?(key)
    @model_class.attribute_names.include?(key)
  end

  def target_key(key)
    MAPPINGS[@model_class][:rename].try(:[], key) || key
  end

  def log(*args)
    line = args.prepend(Time.zone.now.iso8601).join("\t")
    puts line
    @log_file&.puts(line)
  end
end

class AssignedToError < StandardError
end

class RecipientError < StandardError
end

class RequesterError < StandardError
end

class LinkCheckReportEditionError < StandardError
end
