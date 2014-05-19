class FactCheckConfig
  def initialize(address_format)
    unless address_format && address_format.scan("{id}").count == 1
      raise ArgumentError, "Expected '#{address_format}' to contain exactly one '{id}'"
    end

    @prefix, @suffix = address_format.split("{id}")
    @pattern = Regexp.new(
      '\A' +
      Regexp.escape(@prefix) +
      '(.+?)' +
      Regexp.escape(@suffix) +
      '\Z'
    )
  end

  def valid_address?(address)
    @pattern.match(address).present?
  end

  def item_id(address)
    if (match = @pattern.match(address))
      match.captures[0]
    else
      raise ArgumentError, "'#{address}' is not a valid fact check address"
    end
  end

  def address(item_id)
    @prefix + item_id.to_s + @suffix
  end
end
