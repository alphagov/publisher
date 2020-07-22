class FactCheckConfig
  attr_reader :subject_prefix, :reply_to_id

  def initialize(address_format, reply_to_address, subject_prefix = "", reply_to_id = nil)
    unless address_format && address_format.scan("{id}").count == 1
      raise ArgumentError, "Expected '#{address_format}' to contain exactly one '{id}'"
    end

    if reply_to_address.blank?
      raise ArgumentError, "Expected reply_to_address not to be nil"
    end

    @reply_to_address = reply_to_address
    @reply_to_id = reply_to_id

    @subject_prefix = subject_prefix.present? ? subject_prefix + "-" : ""
    @subject_pattern = /\[#{@subject_prefix}(?<id>[0-9a-f]{24})\]/

    @address_prefix, @address_suffix = address_format.split("{id}")
    @address_pattern = Regexp.new(
      '\A' +
      Regexp.escape(@address_prefix) +
      "(.+?)" +
      Regexp.escape(@address_suffix) +
      '\Z',
    )
  end

  def valid_address?(address)
    @address_pattern.match(address).present?
  end

  def item_id_from_address(address)
    if (match = @address_pattern.match(address))
      match.captures[0]
    else
      raise ArgumentError, "'#{address}' is not a valid fact check address"
    end
  end

  def address
    @reply_to_address
  end

  def valid_subject?(subject)
    subject.scan(@subject_pattern).length == 1
  end

  def item_id_from_subject(subject)
    match = subject.scan(@subject_pattern)
    if match.length == 1
      match[0][0]
    elsif match.length > 1
      raise ArgumentError, "'#{subject}' has too many matches"
    else
      raise ArgumentError, "'#{subject}' is not a valid fact check subject"
    end
  end
end
