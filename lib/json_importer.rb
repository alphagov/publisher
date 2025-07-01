# Designed for importing JSON from MongoDB's mongoexport tool
# In this format, each line is one complete JSON object
# There is no surrounding array delimiter, or separating comma
# e.g.
# {"_id": "abc123", "field": "value1"}
# {"_id": "def456", "field": "value2"}
# and so on

class JsonImporter
  include MongoMigrationHelper

  def initialize(model_class:, file:)
    @model_class = model_class.constantize
    @mapper = MongoFieldMapper.new(@model_class)
    @file = file
  end

  def call
    line_no = 0
    processed_line = []

    IO.foreach(@file) do |line|
      log line_no, "Processing"
      processed_line << process_line(line)
      log line_no, "Completed"
      line_no += 1
      processed_line[0]['editionable_id'] = @editionable_id if @model_class == Edition
      unless record_exists?
      model = @model_class.insert(processed_line[0])
      model_id = model[0]['id']
      create_action_and_link_check_reports(model_id, @parsed_obj) if @model_class == Edition
      create_artefact_actions_and_external_links(model_id, @parsed_obj) if @model_class == Artefact
      log(" saved")
      end
      processed_line = []
    rescue AssignedToError => e
      puts "Line: #{line[0..50]}, AssignedToError: #{e.message}"
      log "Line: #{line[0..50]}, AssignedToError: #{e.message}"
    rescue RecipientError => e
      puts "Line: #{line[0..50]}, RecipientError: #{e.message}"
      puts "Edition with mongo_id #{id_value(@parsed_obj)} failed to create Action due to RecipientError"
      log "Line: #{line[0..50]}, RecipientError: #{e.message}"
    rescue RequesterError => e
      puts "Line: #{line[0..50]}, RequesterError: #{e.message}"
      puts "Edition with mongo_id #{id_value(@parsed_obj)} failed to create Action due to RequesterError"
      log "Line: #{line[0..50]}, RequesterError: #{e.message}"
    rescue LinkCheckReportEditionError => e
      puts "Line: #{line[0..50]}, LinkCheckReportEditionError: #{e.message}"
      puts "Edition with mongo_id #{id_value(@parsed_obj)} failed to create LinkCheckReport due to LinkCheckReportEditionError"
      log "Line: #{line[0..50]}, LinkCheckReportEditionError: #{e.message}"
    rescue StandardError => e
      puts "Line: #{line}, StandardError: #{e}"
      puts "Model class #{@model_class} with mongo_id #{id_value(@parsed_obj)} due to Error"
      log "Line: #{line[0..50]}, Error: #{e.message}"
      break
    end
  end

  private

  def record_exists?
    @model_class.attribute_names.include?("mongo_id") && @model_class.where(mongo_id: id_value(@parsed_obj)).exists?
  end

  def process_line(line)
    log("parsing...")
    @parsed_obj = JSON.parse(line)
    @content_type = @parsed_obj['_type']
    create_editionable(@parsed_obj) if @model_class == Edition
    id = id_value(@parsed_obj)
    log(id, " checking existence")
    # if exists?(id)
    #   log(id, " exists, skipping")
    # else
      @mapper.active_record_attributes(@parsed_obj)
    # end
  end

  def id_value(obj)
    if obj["_id"].is_a?(Hash)
      obj["_id"]["$oid"]
    else
      obj["_id"]
    end
  end

  def exists?(mongo_id)
      @model_class.where(mongo_id:).exists?
  end

  def log(*args)
    line = args.prepend(Time.zone.now.iso8601).join("\t")
    Rails.logger.info line
  end
end
