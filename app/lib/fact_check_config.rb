class FactCheckConfig
  attr_reader :subject_prefix, :reply_to_id

  def initialize(reply_to_address, subject_prefix = "", reply_to_id = nil)
    if reply_to_address.blank?
      raise ArgumentError, "Expected reply_to_address not to be nil"
    end

    @reply_to_address = reply_to_address
    @reply_to_id = reply_to_id

    @subject_prefix = subject_prefix.present? ? "#{subject_prefix}-" : ""
    @subject_pattern_with_mongo_id = /\[#{@subject_prefix}(?<id>[0-9a-f]{24})\]/
    @subject_pattern_with_postgres_id = /\[#{@subject_prefix}(?<id>[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\]/
  end

  def address
    @reply_to_address
  end

  def item_id_from_string(string)
    match = string.scan(@subject_pattern_with_postgres_id)

    if match.empty?
      match = string.scan(@subject_pattern_with_mongo_id)
    end

    if match.length == 1
      match[0][0]
    elsif match.length > 1
      raise ArgumentError, "'#{string}' has too many matches"
    end
  end

  def item_id_from_subject_or_body(subject, body = "")
    id = item_id_from_string(subject) || item_id_from_string(body)

    return id if id

    raise ArgumentError, "Message does not contain any fact check ID"
  end
end
