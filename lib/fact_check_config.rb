class FactCheckConfig
  def initialize(address_format, subject_format)
    unless address_format && address_format.scan("{id}").count == 1
      raise ArgumentError, "Expected '#{address_format}' to contain exactly one '{id}'"
    end

    unless subject_format && subject_format.scan("?<id>").count == 1
      raise ArgumentError, "Expected '#{subject_format}' to contain exactly one '?<id>'"
    end

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
