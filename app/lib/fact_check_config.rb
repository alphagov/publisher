class FactCheckConfig
  attr_reader :subject_prefix, :reply_to_id

  def initialize(reply_to_address, subject_prefix = "", reply_to_id = nil)
    if reply_to_address.blank?
      raise ArgumentError, "Expected reply_to_address not to be nil"
    end

    @reply_to_address = reply_to_address
    @reply_to_id = reply_to_id

    @subject_prefix = subject_prefix.present? ? subject_prefix + "-" : ""
    @subject_pattern = /\[#{@subject_prefix}(?<id>[0-9a-f]{24})\]/
  end

  def address
    @reply_to_address
  end

  def contains_id?(string)
    string.scan(@subject_pattern).length == 1
  end

  def item_id_from_string(string)
    match = string.scan(@subject_pattern)
    if match.length == 1
      match[0][0]
    elsif match.length > 1
      raise ArgumentError, "'#{string}' has too many matches"
    else
      raise ArgumentError, "'#{string}' does not contain any fact check ID"
    end
  end

  def item_id_from_subject_or_body(subject, body = "")
    if contains_id?(subject)
      id = item_id_from_string(subject)
    elsif contains_id?(body)
      id = item_id_from_string(body)
    else
      raise ArgumentError, "Message does not contain any fact check ID"
    end

    id
  end
end
