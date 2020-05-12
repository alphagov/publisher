class FactCheckConfig
  attr_reader :subject_prefix, :reply_to_id

  def initialize(address_format, subject_prefix = "", reply_to_id = nil)
    unless address_format && address_format.scan("{id}").count == 1
      raise ArgumentError, "Expected '#{address_format}' to contain exactly one '{id}'"
    end

    @reply_to_id = reply_to_id

    @subject_prefix = subject_prefix.present? ? subject_prefix + "-" : ""
    subject_format = "‘\\[.+?\\]’ GOV.UK preview of new edition \\[#{@subject_prefix}(?<id>.+?)\\]"

    @address_prefix, @address_suffix = address_format.split("{id}")
    @address_pattern = Regexp.new(
      '\A' +
      Regexp.escape(@address_prefix) +
      "(.+?)" +
      Regexp.escape(@address_suffix) +
      '\Z',
    )

    @subject_pattern = Regexp.new(
      '\A.*' +
      subject_format +
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

  def address(item_id)
    @address_prefix + item_id.to_s + @address_suffix
  end

  def valid_subject?(subject)
    @subject_pattern.match(subject).present?
  end

  def item_id_from_subject(subject)
    if (match = @subject_pattern.match(subject))
      match[:id]
    else
      raise ArgumentError, "'#{subject}' is not a valid fact check address"
    end
  end
end
