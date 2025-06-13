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
    # PublishIntent => {
    #   rename: {
    #     "_id" => "base_path",
    #   },
    #   process: {
    #     "publish_time" => ->(key, value) { { key => unpack_datetime(value) } },
    #     "created_at" => ->(key, value) { rails_timestamp(key, value) },
    #     "updated_at" => ->(key, value) { rails_timestamp(key, value) },
    #
    #   },
    # },
    # ScheduledPublishingLogEntry => {
    #   process: {
    #     "_id" => ->(_key, value) { { "mongo_id" => value["$oid"] } },
    #     "scheduled_publication_time" => ->(key, value) { { key => unpack_datetime(value) } },
    #     "created_at" => ->(key, value) { rails_timestamp(key, value) },
    #   },
    # },
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

  # Return the given key with the unpacked date value if given,
  # otherwise return empty hash, to avoid conflicting with
  # the not-null constraint on Rails' timestamp keys
  def self.rails_timestamp(key, value)
    date = unpack_datetime(value)
    date ? { key => date } : {}
  end

  private

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
