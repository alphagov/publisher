# Maps fields from a source Mongo JSON object
# into the corresponding field in our ActiveRecord models
class MongoFieldMapper
  MAPPINGS = {
    Edition => {
      rename: {
        "_type" => "editionable_type",
      },
      process: {
        "_id" => ->(_key, value) { { "mongo_id" => value["$oid"] } },
        "assigned_to_id" => ->(_key, value) { { "assigned_to_id" => get_assigned_to_id(value) } },
        "created_at" => ->(key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(key, value) { rails_timestamp(key, value) },
        "review_requested_at" => ->(key, value) { rails_timestamp(key, value) },
      },
    },
    LocalTransactionEdition => {
      process: {
        "created_at" => ->(key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(key, value) { rails_timestamp(key, value) },
      },
    },
    GuideEdition => {
      process: {
        "created_at" => ->(key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(key, value) { rails_timestamp(key, value) },
      },
    },
    SimpleSmartAnswerEdition => {
      process: {
        "created_at" => ->(key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(key, value) { rails_timestamp(key, value) },
      },
    },
    PlaceEdition => {
      process: {
        "created_at" => ->(key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(key, value) { rails_timestamp(key, value) },
      },
    },
    AnswerEdition => {
      process: {
        "created_at" => ->(key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(key, value) { rails_timestamp(key, value) },
      },
    },
    PopularLinksEdition => {
      process: {
        "created_at" => ->(key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(key, value) { rails_timestamp(key, value) },
      },
    },
    TransactionEdition => {
      process: {
        "created_at" => ->(key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(key, value) { rails_timestamp(key, value) },
      },
    },
    HelpPageEdition => {
      process: {
        "created_at" => ->(key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(key, value) { rails_timestamp(key, value) },
      },
    },
    Part => {
      process: {
        "_id" => ->(_key, value) { { "mongo_id" => value["$oid"] } },
        "created_at" => ->(key, value) { rails_timestamp(key, value) },
      },
    },
    DevolvedAdministrationAvailability => {
      process: {
        "_id" => ->(_key, value) { { "mongo_id" => value["$oid"] } },
        "created_at" => ->(key, value) { rails_timestamp(key, value) },
      },
    },
    SimpleSmartAnswerEdition::Node => {
      process: {
        "_id" => ->(_key, value) { { "mongo_id" => value["$oid"] } },
        "created_at" => ->(key, value) { rails_timestamp(key, value) },
      },
    },
    SimpleSmartAnswerEdition::Node::Option => {
      process: {
        "_id" => ->(_key, value) { { "mongo_id" => value["$oid"] } },
        "created_at" => ->(key, value) { rails_timestamp(key, value) },
      },
    },
    User => {
      process: {
        "_id" => ->(_key, value) { { "mongo_id" => value["$oid"] } },
        "updated_at" => ->(key, value) { rails_timestamp(key, value) },
        "created_at" => ->(key, value) { rails_timestamp(key, value) },
      },
    },
    Action => {
      process: {
        "_id" => ->(_key, value) { { "mongo_id" => value["$oid"] } },
        "recipient_id" => ->(_key, value) { { "recipient_id" => get_recipient_id(value) } },
        "requester_id" => ->(_key, value) { { "requester_id" => get_requester_id(value) } },
        "created_at" => ->(key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(key, value) { rails_timestamp(key, value) },
      },
    },
    Artefact => {
      process: {
        "_id" => ->(_key, value) { { "mongo_id" => value["$oid"] } },
        "created_at" => ->(key, value) { rails_timestamp(key, value) },
        "updated_at" => ->(key, value) { rails_timestamp(key, value) },
        "public_timestamp" => ->(key, value) { rails_timestamp(key, value) },
      },
    },
    ArtefactAction => {
      process: {
        "_id" => ->(_key, value) { { "mongo_id" => value["$oid"] } },
        "user_id" => ->(_key, value) { { "user_id" => get_artefact_action_user_id(value) } },
        "created_at" => ->(key, value) { rails_timestamp(key, value) },
      },
    },
  }.freeze

  def initialize(model_class)
    @model_class = model_class
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

  def self.get_assigned_to_id(value)
    assigned_to_user = User.where(mongo_id: value["$oid"]).last
    if assigned_to_user.nil?
      puts "Error: user with mongo_id #{value['$oid']} does not exist"
      raise AssignedToError, "Error: user with mongo_id #{value['$oid']} does not exist"
    else
      assigned_to_user.id
    end
  end

  def self.get_recipient_id(value)
    recipient = User.where(mongo_id: value["$oid"]).last
    if recipient.nil?
      puts "Error: user with mongo_id #{value['$oid']} does not exist"
      raise RecipientError, "Error: user with mongo_id #{value['$oid']} does not exist"
    else
      recipient.id
    end
  end

  def self.get_requester_id(value)
    requester = User.where(mongo_id: value["$oid"]).last
    if requester.nil?
      puts "Error: user with mongo_id #{value['$oid']} does not exist"
      raise RequesterError, "Error: user with mongo_id #{value['$oid']} does not exist"
    else
      requester.id
    end
  end

  def self.get_artefact_action_user_id(value)
    return if value.nil?

    artefact_action_user = User.where(mongo_id: value["$oid"]).last
    if artefact_action_user.nil?
      puts "Error: user with mongo_id #{value['$oid']} does not exist so inserted 'Dummy user' id"
      gds_organisation_id = "af07d5a5-df63-4ddc-9383-6a666845ebe9"

      get_dummy_user_id(gds_organisation_id)
      return User.where(name: 'Dummy user').last.id
    else
      artefact_action_user.id
    end
  end

  # Return the given key with the unpacked date value if given,
  # otherwise return empty hash, to avoid conflicting with
  # the not-null constraint on Rails' timestamp keys
  def self.rails_timestamp(key, value)
    date = unpack_datetime(value)
    date ? { key => date } : {}
  end

private

  def self.get_dummy_user_id(gds_organisation_id)
    dummy_user = User.where(name: "Dummy user")

    if dummy_user.exists?
      return dummy_user.last.id
    end

    User.create!(
      name: "Dummy user",
      permissions: %w[signin],
      organisation_content_id: gds_organisation_id,
    )
  end

  def process(key, value)
    if (proc = MAPPINGS[@model_class][:process][key])
      proc.call(key, value)
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
end

class AssignedToError < StandardError
end

class RecipientError < StandardError
end

class RequesterError < StandardError
end